#!/bin/bash
# SOPS helper script for dotenv files and secrets directory

set -euo pipefail

# Function to encrypt files
encrypt_file() {
	local input_file="$1"
	local output_file="${2:-}"

	# If no output file specified, determine based on input location
	if [[ -z "$output_file" ]]; then
		if [[ "$input_file" == secrets/* ]]; then
			# For secrets directory, replace .dec with .enc extension
			if [[ "$input_file" == *.dec ]]; then
				output_file="${input_file%.dec}.enc"
			else
				# For files without .dec, add .enc extension
				output_file="${input_file}.enc"
			fi
		else
			# For other files (like .secrets.env), add .enc extension
			output_file="${input_file}.enc"
		fi
	fi

	# Use SOPS without format specification - let .sops.yaml handle it
	sops -e "$input_file" >"$output_file"
	echo "Encrypted: $input_file -> $output_file"
}

# Function to decrypt files
decrypt_file() {
	local input_file="$1"
	local output_file="${2:-}"

	# If no output file specified, determine based on input location
	if [[ -z "$output_file" ]]; then
		if [[ "$input_file" == secrets/* ]]; then
			# For secrets directory, replace .enc with .dec extension
			output_file="${input_file%.enc}.dec"
		else
			# For other files (like .secrets.env.enc), remove .enc extension
			output_file="${input_file%.enc}"
		fi
	fi

	# Decrypt without format specification
	sops -d "$input_file" >"$output_file"
	echo "Decrypted: $input_file -> $output_file"
}

# Function to encrypt all files in secrets directory
encrypt_secrets_dir() {
	if [[ ! -d "secrets" ]]; then
		echo "Error: secrets/ directory not found"
		exit 1
	fi

	echo "Encrypting all files in secrets/ directory..."
	# Find .dec files to encrypt to .enc, or any files without .enc extension
	find secrets -type f \( -name "*.dec" -o \( ! -name "*.enc" ! -name "*.dec" \) \) | while read -r file; do
		encrypt_file "$file"
	done
}

# Function to decrypt all .enc files in secrets directory
decrypt_secrets_dir() {
	if [[ ! -d "secrets" ]]; then
		echo "Error: secrets/ directory not found"
		exit 1
	fi

	echo "Decrypting all .enc files in secrets/ directory..."
	find secrets -type f -name "*.enc" | while read -r file; do
		decrypt_file "$file"
	done
}

# Main script
case "$1" in
encrypt)
	if [[ "$2" == "secrets" || "$2" == "secrets/" ]]; then
		encrypt_secrets_dir
	else
		encrypt_file "$2" "${3:-}"
	fi
	;;
decrypt)
	if [[ "$2" == "secrets" || "$2" == "secrets/" ]]; then
		decrypt_secrets_dir
	else
		decrypt_file "$2" "${3:-}"
	fi
	;;
*)
	echo "Usage: $0 {encrypt|decrypt} <input_file|secrets> [output_file]"
	echo ""
	echo "Single file operations:"
	echo "  $0 encrypt auth/.secrets.env"
	echo "  $0 decrypt auth/.secrets.env.enc"
	echo "  $0 encrypt secrets/.authentik.env.dec  # Encrypts .dec -> .enc"
	echo "  $0 decrypt secrets/.authentik.env.enc  # Decrypts .enc -> .dec"
	echo ""
	echo "Bulk operations for secrets directory:"
	echo "  $0 encrypt secrets     # Encrypt all .dec files to .enc in secrets/"
	echo "  $0 decrypt secrets     # Decrypt all .enc files to .dec in secrets/"
	exit 1
	;;
esac
