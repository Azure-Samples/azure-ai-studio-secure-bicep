# Checks if a specific command is available on your system.
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Processes named command-line arguments into variables.
parse_args() {
  # $1 - The associative array name containing the argument definitions and default values
  # $2 - The arguments passed to the script
  local -n arg_defs=$1
  shift
  local args=("$@")

  # Assign default values first for defined arguments
  for arg_name in "${!arg_defs[@]}"; do
    declare -g "$arg_name"="${arg_defs[$arg_name]}"
  done

  # Process command-line arguments
  for ((i = 0; i < ${#args[@]}; i++)); do
    arg=${args[i]}
    if [[ $arg == --* ]]; then
      arg_name=${arg#--}
      next_index=$((i + 1))
      next_arg=${args[$next_index]}

      # Check if the argument is defined in arg_defs
      if [[ -z ${arg_defs[$arg_name]+_} ]]; then
        # Argument not defined, skip setting
        continue
      fi

      if [[ $next_arg == --* ]] || [[ -z $next_arg ]]; then
        # Treat as a flag
        declare -g "$arg_name"=1
      else
        # Treat as a value argument
        declare -g "$arg_name"="$next_arg"
        ((i++))
      fi
    else
      break
    fi
  done
}

# Installs unzip, if it is not already installed.
install_unzip() {
  if ! command_exists unzip; then
    echo "[unzip] is not installed. Installing [unzip]..."
    sudo apt-get update && sudo apt-get install -y unzip
    if command_exists unzip; then
      echo "[unzip] successfully installed."
    else
      echo "Failed to install [unzip]."
      exit 1
    fi
  else
    echo "[unzip] is already installed."
  fi
}

# Installs yq, for processing YAML files, if it is not already installed.
install_yq() {
  if ! command_exists yq; then
    echo "[yq] is not installed. Installing [yq]..."
    sudo apt-get update && sudo apt-get install -y jq # jq is a prerequisite for yq
    sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.25.1/yq_linux_amd64"
    sudo chmod +x /usr/local/bin/yq
    if command_exists yq; then
      echo "[yq] successfully installed."
    else
      echo "Failed to install [yq]."
      exit 1
    fi
  else
    echo "[yq] is already installed."
  fi
}

# Installs Python and pip, if they are not already installed.
install_python_and_pip() {
  if ! command_exists python3; then
    echo "[Python3] is not installed. Installing [Python3]..."
    sudo apt-get update && sudo apt-get install -y python3
    if command_exists python3; then
      echo "[Python3] successfully installed."
    else
      echo "Failed to install [Python3]."
      exit 1
    fi
  else
    echo "[Python3] is already installed."
  fi

  if ! command_exists pip3; then
    echo "[pip3] is not installed. Installing [pip3]..."
    sudo apt-get update && sudo apt-get install -y python3-pip
    if command_exists pip3; then
      echo "[pip3] successfully installed."
    else
      echo "Failed to install [pip3]."
      exit 1
    fi
  else
    echo "[pip3] is already installed."
  fi
}

# Installs the promptflow tools, if they are not already installed.
install_promptflow() {
  if sudo pip3 show promptflow >/dev/null 2>&1; then
    echo "[promptflow] is already installed."
  else
    echo "Installing promptflow using pip3..."
    sudo pip3 install promptflow --upgrade
    if sudo pip3 show promptflow >/dev/null 2>&1; then
      echo "[promptflow] successfully installed."
    else
      echo "Failed to install [promptflow]."
      exit 1
    fi
  fi

  if ! command_exists pfazure; then
    echo "[promptflow[azure]] is not installed. Installing [promptflow[azure]]..."
    sudo pip3 install promptflow[azure] --upgrade
    if command_exists pfazure; then
      echo "[promptflow[azure]] successfully installed."
    else
      echo "Failed to install [promptflow[azure]]."
      exit 1
    fi
  else
    echo "[promptflow[azure]] is already installed."
  fi
}

# Replaces a field value in a YAML file using yq.
replace_yaml_field() {
  local yaml_file="$1"
  local field_path="$2"
  local search_value="$3"
  local replace_value="$4"

  yq eval ".${field_path} |= sub(\"${search_value}\", \"${replace_value}\")" "$yaml_file" -i
}

# Sets a new value for a field in a YAML file using yq.
set_yaml_field() {
  local yaml_file="$1"
  local field_path="$2"
  local new_value="$3"

  yq eval ".${field_path} = \"${new_value}\"" "$yaml_file" -i
}

# Generates a new file name with the current date and time appended.
generate_new_filename() {
  local file=$1

  # Check if the input file is provided
  if [[ -z "$file" ]]; then
    echo "Usage: generate_new_filename <file_name>"
    return 1
  fi

  # Extract the file name without the extension
  local filename=$(basename "$file")
  local name="${filename%.*}"
  local extension="${filename##*.}"

  # Get the current date and time to the second
  local current_datetime=$(date +"%Y-%m-%d-%H-%M-%S")

  # Construct the new file name
  local new_file_name="${name}-${current_datetime}.${extension}"

  # Output the new file name
  echo "$new_file_name"
}

# Creates a new directory, removing any existing directory with the same name.
create_new_directory() {
  local directory=$1

  # Check if the directory exists and remove it if it does
  if [ -d "$directory" ]; then
    rm -rf "$directory"
    if [ $? -eq 0 ]; then
      echo "The [$directory] directory was removed successfully."
    else
      echo "An error occurred while removing the [$directory] directory."
      exit -1
    fi
  fi

  # Create the new directory
  mkdir -p "$directory"
  if [ $? -eq 0 ]; then
    echo "The [$directory] directory was created successfully."
  else
    echo "An error occurred while creating the [$directory] directory."
    exit -1
  fi
}

# Removes a directory and all its subdirectories and files.
remove_directory() {
  local directory=$1

  # Check if the directory exists
  if [ -d "$directory" ]; then
    # Remove the directory and its contents
    rm -rf "$directory"
    if [ $? -eq 0 ]; then
      echo "The [$directory] directory and its contents were removed successfully."
    else
      echo "An error occurred while removing the [$directory] directory."
      exit -1
    fi
  else
    echo "The [$directory] directory does not exist."
    exit -1
  fi
}

# Unzips an archive file to a specified directory.
unzip_archive() {
  local archiveFilePath=$1
  local destinationDirectory=$2

  echo "Unzipping the [$archiveFilePath] archive to [$destinationDirectory] directory..."
  unzip -q -o "$archiveFilePath" -d "$destinationDirectory"

  if [ $? -eq 0 ]; then
    echo "The archive was unzipped successfully to [$destinationDirectory] directory."
  else
    echo "An error occurred while unzipping the archive to [$destinationDirectory] directory."
    exit -1
  fi
}
