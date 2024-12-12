#! /bin/bash
echo "This is a tool to migrate Svelte 3.x to Svelte 5"

# Prompt the user for the project name
read -p "Enter the project name: " project_name

# Load nvm and use Node.js 22
export NVM_DIR="$HOME/.nvm"
# Make sure nvm is loaded by sourcing its script
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Function to delete specific files and directories no longer needed
clean_old_files() {
  echo "Cleaning up old files and directories no longer need on Svelte 5"

  # Array of files and directories to delete
  files_to_delete=(
    "node_modules"
    "package-lock.json"
    "rollup.config.js"
    "scripts"
    "public/build"
  )

  # Loop through each file/directory and delete if it exists
  for item in "${files_to_delete[@]}"; do
    if [ -e "$item" ]; then
      rm -rf "$item"
      echo "Deleted $item"
    else
      echo "$item does not exist, skipping..."
    fi
  done
}

# Move files from old website make it work on svelte 5. Move everything except 'old', 'LICENSE', and 'migrate.sh' into 'old'
move_files() {
  # Define an array of items to exclude
  local exclude=("old" "LICENSE" "migrate.sh" ".DS_Store" ".git" "$project_name")

  # Loop through each item in the current directory, including hidden files
  for item in * .*; do
    # Skip the excluded items and the current (.) and parent (..) directories
    if [[ ! " ${exclude[@]} " =~ " ${item} " ]] && [[ "$item" != "." ]] && [[ "$item" != ".." ]]; then
      mv "$item" old/
      echo "Moved $item to 'old/'"
    fi
  done

  # use this line to simulate a failure
  # mv non_existent_file.txt old/
}


# Move all files and directories from '"$project_name"' to the root directory
move_new_project_to_root() {
  echo "Moving files from '"$project_name"' to root directory..."

  # Use 'shopt' to enable moving hidden files as well
  shopt -s dotglob

  # Move everything from '"$project_name"' to the current directory (root)
  mv "$project_name"/* .

  # Disable dotglob to avoid affecting other operations
  shopt -u dotglob

  # Remove the now-empty '"$project_name"' directory
  rmdir "$project_name"
  echo "'"$project_name"' directory contents moved to root and directory removed."
}

# Function to clean and move files
move_and_cleanup_directories() {
  # Step 1: Delete everything inside 'src/lib'
  if [ -d "src/lib" ]; then
    rm -rf src/lib/*
    echo "Cleared all contents of 'src/lib'."
  else
    echo "'src/lib' directory does not exist..."
    # mkdir -p src/lib
  fi

  # Step 2: Move everything from 'old/src/components' into 'src/lib'
  if [ -d "old/src/components" ]; then
    mv old/src/components/* src/lib/
    echo "Moved all contents from 'old/src/components' to 'src/lib'."
  else
    echo "'old/src/components' directory does not exist. Nothing to move."
  fi

  # Step 3: Move 'old/src/js' to 'src'
  if [ -d "old/src/js" ]; then
    mv old/src/js src/
    echo "Moved 'old/src/js' to 'src/'."
  else
    echo "'old/src/js' directory does not exist. Nothing to move."
  fi

  # Step 4: Move 'old/src/scss' to 'src'
  if [ -d "old/src/scss" ]; then
    mv old/src/scss src/
    echo "Moved 'old/src/scss' to 'src/'."
  else
    echo "'old/src/scss' directory does not exist. Nothing to move."
  fi

  # Step 5: Move 'old/src/data.js' to 'src'
  if [ -f "old/src/data.js" ]; then
    mv old/src/data.js src/
    echo "Moved 'old/data.js' to 'src'."
  else
    echo "'old/src/data.js' does not exist. Nothing to move."
  fi

  # Step 5: Clear and move contents into 'public'
  if [ -d "public" ]; then
    rm -rf public/*
    echo "Cleared all contents of 'public'."
  else
    echo "'public' directory does not exist..."
    # mkdir -p public
  fi

  if [ -d "old/public" ]; then
    mv old/public/* public/
    echo "Moved all contents from 'old/public' to 'public'."
  else
    echo "'old/public' directory does not exist. Nothing to move."
  fi
  
  # Step 6: Delete 'src/app.css' if it exists
  if [ -f "src/app.css" ]; then
    rm src/app.css
    echo "Deleted 'src/app.css'."
  else
    echo "'src/app.css' does not exist. Nothing to delete."
  fi

  # Step 7: Delete 'src/assets' if it exists
  if [ -d "src/assets" ]; then
    rm -rf src/assets
    echo "Deleted 'src/assets'."
  else
    echo "'src/assets' does not exist. Nothing to delete."
  fi
}

update_npm_version() {
  npm version major
}

install_packages() {
  # Run npm install to set up the project dependencies
  echo "Installing project dependencies..."
  npm install
  
  # Install sass as dev dependency
  echo "Installing sass..."
  npm i -D sass
  
  # Install the specific version of svelte-select as dev dependency
  echo "Installing svelte-select version 4.4.7..."
  npm i -D svelte-select@4.4.7

  # Install d3-fetch
  echo "Installing d3-fetch version..."
  npm i d3-fetch
}

update_gitignore() {
  # Add the next directories and files: old, package-lock.json and migrate.sh
  echo -e "\n# Added by migration script\nold\npackage-lock.json\nmigrate.sh" >> .gitignore
}

run_script() {
  # Check if the directory "old" exists?
  if [ ! -d "old" ]; then
    # If do not exist, create it
    mkdir old
    echo "'old' directory was created"

    # call function to clean old files
    clean_old_files
    nvm use 22
    npm create vite@latest

    # Check if the previous command was successful
    if [ $? -eq 0 ] && [ -d "$project_name" ]; then
      # Call function to move files if Vite project creation was successful
      move_files
      move_files_status=$?  # Store the exit status of move_files
      
      # If move_files executed successfully, call move_new_project_to_root
      if [ $move_files_status -eq 0 ]; then
        move_new_project_to_root
        move_new_project_to_root_status=$? # Store the exit status of move_new_project_to_root

        # If move_new_project_to_root was successful, call move_and_cleanup_directories
        if [ $move_new_project_to_root_status -eq 0 ]; then
          # Call the function where needed in your script
          move_and_cleanup_directories
          move_and_cleanup_directories_status=$?

          if [ $move_and_cleanup_directories_status -eq 0 ]; then
            install_packages
            install_packages_status=$?

            if [ $install_packages_status -eq 0 ]; then
              update_gitignore
              # update_npm_version
              # rm -rf old
              # echo "Message: 'old' directory removed."
              echo "CONGRATS! Everything went smooth. Now you might need to do some manual tweaks to run the project."
            else
              echo "Error: install_packages function failed. Nothing removed."
              exit 1 # End the script with a non-zero status to indicate an error
            fi
          else
            echo "Error: move_and_cleanup_directories function failed. Aborting installing packages."
            exit 1 # End the script with a non-zero status to indicate an error
          fi
        else
          echo "Error: move_and_cleanup_directories function failed. Aborting move."
          exit 1 # End the script with a non-zero status to indicate an error
        fi
      else
        echo "Error: move_files function failed. Aborting root directory move."
        echo "Message: '"$project_name"' and 'old' directory removed."
        rm -rf "$project_name" old
        git restore .
        exit 1 # End the script with a non-zero status to indicate an error
      fi
    else
      echo "Error: Failed to create Svelte project. Aborting file move."
      exit 1 # End the script with a non-zero status to indicate an error
    fi

  else
    echo "'Old' directory already exists. Removing 'old' directory..."
    rm -rf old
    run_script
  fi
}

run_script
