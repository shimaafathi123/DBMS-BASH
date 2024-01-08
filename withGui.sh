#! /bin/bash
shopt -s extglob
export LC_COLLATE=C

# ================================<< Start of (( Directory Variables )) >>================================

# Directory to store databases (same as the script file directory)
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
DATABASE_DIR="$SCRIPT_DIR/databases"

# another DATABASE_DIR possible to use (makes databases stored in the user home directory)
# DATABASE_DIR="/home/$(whoami)/Databases/"

# Create the directory if it doesn't exist
mkdir -p "$DATABASE_DIR"

# Variable to track the current database
currentDb=""

# ================================<< End of (( Directory Variables )) >>================================

# ================================<< Start of (( Functions of DBMS )) >>================================

# Function to create a new database
function createDatabase() {
    dbName=$(zenity --entry --title="Create Database" --text="Enter the database name:")
    dbPath="$DATABASE_DIR/$dbName"
    
    if [[ ! $dbName =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        zenity --error --text="Invalid database name. Database names must start with a letter or underscore and only contain letters, numbers, and underscores."
    elif [ -d "$dbPath" ]; then
        zenity --info --text="Database '$dbName' already exists."
    else
        mkdir "$dbPath"
        zenity --info --text="Database '$dbName' created successfully."
    fi
}

# Function to list all databases
function listDatabase() {
    if [ -z "$(ls $DATABASE_DIR)" ]; then
        zenity --info --text="No Databases found."
        return
    fi

    databases=$(ls "$DATABASE_DIR")
    zenity --info --text="Available databases:\n$databases"
}

# Function to connect to a database
function connectToDatabase() {
    dbName=$(zenity --entry --title="Connect to Database" --text="Enter the database name:")
    dbPath="$DATABASE_DIR/$dbName"
    
    if [ -z "$dbName" ]; then
        zenity --error --text="Database name cannot be empty. Aborting Database connect."
    elif [ -d "$dbPath" ]; then
        currentDb="$dbPath"
        zenity --info --text="Connected to database '$dbName'."
        runSubMenu
    else
        zenity --error --text="Database '$dbName' not found."
    fi
}

# Function to drop a database
function dropDatabase() {
    dbName=$(zenity --entry --title="Drop Database" --text="Enter the database name to drop:")
    dbPath="$DATABASE_DIR/$dbName"
    
    if [ -z "$dbName" ]; then
        zenity --error --text="Database name cannot be empty. Aborting Database drop."
    elif [ -d "$dbPath" ]; then
        rm -r "$dbPath"
        zenity --info --text="Database '$dbName' dropped successfully."
    else
        zenity --error --text="Database '$dbName' not found."
    fi
}


# Function to create a new table
function validateName() {
    local name=$1
    if [[ $name =~ ^[A-Za-z_]{1}[A-Za-z0-9]*$ ]]; then
        return 0 # Valid name
    else
        echo "Invalid name: $name"
        return 1 # Invalid name
    fi
}
# Function to create a new table with GUI
function createTable() {
    echo "createTable function is called."

    # Input table name with GUI
    tableName=$(zenity --entry --title="Create Table" --text="Enter table name:")

    # Validate table name
    if ! validateName "$tableName"; then
        zenity --error --text="Invalid table name. Please enter a valid name."
        return
    fi

    # Check if table already exists
    if [[ -d "$currentDb/$tableName" ]]; then
        zenity --info --text="Table '$tableName' already exists."
        return
    fi

    # Input number of columns with GUI
    columns=$(zenity --entry --title="Create Table" --text="Enter number of columns:")

    # Check if the input is a positive integer
    if ! [[ $columns =~ ^[1-9][0-9]*$ ]]; then
        zenity --error --text="Invalid input. Please enter a valid positive integer for the number of columns."
        return
    fi

    # Create table directory
    mkdir -p "$currentDb/$tableName" || { zenity --error --text="Error creating table directory."; return; }

    # Create metadata file for table
    touch "$currentDb/$tableName/metadata" || { zenity --error --text="Error creating metadata file."; return; }

    # Create data file for table
    touch "$currentDb/$tableName/data" || { zenity --error --text="Error creating data file."; return; }

    # Input primary key column with GUI
    primaryKeyColName=$(zenity --entry --title="Create Table" --text="Enter Primary Key Column Name:")

    # Check if the column name is already used
    if [[ " ${columnNames[@]} " =~ " $primaryKeyColName " ]] || ! validateName "$primaryKeyColName"; then
        zenity --error --text="Name validation error. Please enter a valid and non-duplicated name for the primary key column."
        return
    fi

    # Input data type for primary key with GUI
    primaryKeyDataType=$(zenity --list --title="Create Table" --text="Select Data Type for $primaryKeyColName" --column="Options" "int" "str" "boolean")

    # Check if the entered data type is valid
    if [[ ! "$primaryKeyDataType" =~ ^(int|str|boolean)$ ]]; then
        zenity --error --text="Invalid data type. Please enter 'int', 'str', or 'boolean'."
        return
    fi

    # Append primary key column info to metadata file
    echo "$primaryKeyColName|$primaryKeyDataType|yes" >>"$currentDb/$tableName/metadata"

    # Loop through remaining columns with GUI
    columnNames=()
    for ((i = 2; i <= columns; i++)); do
        # Input column name with GUI
        colName=$(zenity --entry --title="Create Table" --text="Enter Column $i Name:")

        # Check if the column name is already used
        if [[ " ${columnNames[@]} " =~ " $colName " ]] || ! validateName "$colName"; then
            zenity --error --text="Name validation error. Please enter a valid and non-duplicated name for Column $i."
            return
        fi

        columnNames+=("$colName")

        # Input data type with GUI
        datatype=$(zenity --list --title="Create Table" --text="Select Data Type for $colName" --column="Options" "int" "str" "boolean")

        # Check if the entered data type is valid
        if [[ ! "$datatype" =~ ^(int|str|boolean)$ ]]; then
            zenity --error --text="Invalid data type. Please enter 'int', 'str', or 'boolean'."
            return
        fi

        # Append column info to metadata file
        echo "$colName|$datatype|no" >>"$currentDb/$tableName/metadata"
    done

    # Store column names in the first row of the data file with "|"
    echo "${primaryKeyColName} ${columnNames[*]}" | tr ' ' '|' >>"$currentDb/$tableName/data"

    # Append "|" to the first line of the data file
    sed -i '1s/$/|/' "$currentDb/$tableName/data"

    zenity --info --text="Table $tableName created successfully."
}  # End Create Table function




# Function to list all tables in the current database
# Function to list all tables in the current database with GUI
function listTable() {
    echo "listTable function is called."

    if [ -z "$currentDb" ]; then
        zenity --error --text="No database selected. Please connect to a database first."
        return
    fi

    # Capture the absolute path of the current database directory
    currentDbPath=$(realpath "$currentDb")

    # Check if the database is empty
    if [ -z "$(ls -A "$currentDbPath")" ]; then
        zenity --info --text="No tables found in the current database."
        return
    fi

    tables=$(ls "$currentDbPath" | zenity --list --title="Tables" --column="Tables" --text="Tables in the current database:" --separator='' --multiple --height=300 --width=300)

    if [ -z "$tables" ]; then
        zenity --info --text="No tables selected."
    else
        zenity --info --text="Selected tables:\n$tables"
    fi
} # End list Table function
# Function to drop a table from the specified database with GUI
function dropTable() {
    echo "dropTable function is called."

    if [ -z "$currentDb" ]; then
        zenity --error --text="No database selected. Please connect to a database first."
        return
    fi

    # Capture the absolute path of the current database directory
    currentDbPath=$(realpath "$currentDb")

    # List only directories (tables), not regular files
    tables=()
    for table in "$currentDbPath"/*; do
        if [ -d "$table" ]; then
            tables+=("$(basename "$table")")
        fi
    done

    # Check if there are no tables
    if [ ${#tables[@]} -eq 0 ]; then
        zenity --info --text="No tables found in the current database."
        return
    fi

    # Display a list of tables for the user to choose from
    selectedTable=$(zenity --list \
                            --title="Select Table to Drop" \
                            --column="Tables" \
                            --text="Tables in the current database:" \
                            "${tables[@]}")

    if [ -z "$selectedTable" ]; then
        zenity --info --text="No table selected."
    else
        tablePath="$currentDbPath/$selectedTable"

        # Confirm before dropping the table
        confirm=$(zenity --question --text="Are you sure you want to drop table '$selectedTable'?")

        if [ $? -eq 0 ]; then
            rm -r "$tablePath" || { zenity --error --text="Error dropping table '$selectedTable'."; return; }
            zenity --info --text="Table '$selectedTable' dropped successfully."
        else
            zenity --info --text="Table drop aborted."
        fi
    fi
} # End of Drop Table




# Function to insert into a table with GUI
function insertIntoTable() {
    echo "insertIntoTable function is called."

    if [ -z "$currentDb" ]; then
        zenity --error --text="No database selected. Please connect to a database first."
        return
    fi

    # Get the list of tables in the current database
    tables=$(ls "$currentDb" | grep -vE '\.txt$')  # Exclude text files from the list

    # Select a table using Zenity
    tableName=$(zenity --list --title="Insert Into Table" --text="Select a table:" --column="Tables" $tables)

    if [ -z "$tableName" ]; then
        zenity --info --text="No table selected. Aborting insert operation."
        return
    fi

    tablePath="$currentDb/$tableName"

    if [ -d "$tablePath" ]; then
        # Ask the user whether to insert columns or data into columns
        operation=$(zenity --list --title="Insert Into Table" --text="Choose operation:" --column="Options" "Insert Columns" "Insert Data")

        case $operation in
                "Insert Columns")
                    while true; do
                        read -p "Enter the number of columns: " numColumns

                        # Check if the input is a positive integer
                        if [[ $numColumns =~ ^[1-9][0-9]*$ ]]; then
                            break
                        else
                            echo "Invalid input. Please enter a valid positive integer for the number of columns."
                        fi
                    done

                    # Prompt for metadata for each column
                    declare -a metadata=()
                    declare -a columnNames=()
                    for ((i = 1; i <= numColumns; i++)); do
                        while true; do
                            # Input column name
                            read -p "Enter Column $i Name: " colName

                            # Check if the column name is already used
                            while grep -q "^$colName|" "$tablePath/metadata"; do
                                echo "Column '$colName' already exists. Please enter a unique column name."
                                read -p "Enter Column $i Name: " colName
                            done

                            # Validate column name
                            if validateName "$colName"; then
                                break
                            else
                                echo "Name validation error. Please enter a valid name for Column $i."
                            fi
                        done

                        while true; do
                            read -p "Enter metadata for $colName (int/str/bool): " columnType
                            case $columnType in
                                "int" | "str" | "bool")
                                    break
                                    ;;
                                *)
                                    echo "Invalid column type. Please enter 'int', 'str', or 'bool'."
                                    ;;
                            esac
                        done

                        # Automatically set primary key as "no"
                        isPrimaryKey="no"

                        metadata+=("$colName|$columnType|$isPrimaryKey")
                        columnNames+=("$colName")
                    done

                    # Append column names to the first row of the data file
                    existingColumns=$(head -n 1 "$tablePath/data")

                    if [[ ! "$existingColumns" =~ \| ]]; then
                        # Add a trailing | if it doesn't exist
                        existingColumns="${existingColumns}|"
                    fi

                    allColumns="${existingColumns}${columnNames[0]}"

                    for ((i = 1; i < ${#columnNames[@]}; i++)); do
                        allColumns="${allColumns}|${columnNames[i]}"
                    done

                    allColumns="${allColumns}|"
                    echo "$allColumns" >"$tablePath/data"

                    # Append metadata to the metadata file
                    printf "%s\n" "${metadata[@]}" >>"$tablePath/metadata"
                    echo "Columns inserted successfully into table '$tableName'."

                    # Save column names to separate files for later use in select
                    for colName in "${columnNames[@]}"; do
                        touch "$tablePath/${colName}_list"
                    done

                    break
                    ;;

           "Insert Data")
    # Read metadata from the metadata file
    metadata=$(<"$tablePath/metadata")
    IFS=$'\n' read -rd '' -a metadataArray <<<"$metadata"

    # Validate and insert data
    declare -a values=()
    for meta in "${metadataArray[@]}"; do
        IFS='|' read -ra metaArray <<<"$meta"
        column="${metaArray[0]}"
        columnType="${metaArray[1]}"
        isPrimaryKey="${metaArray[2]}"

        # If column is a primary key, validate and insert the value
        if [ "$isPrimaryKey" == "yes" ]; then
            while true; do
                echo -n "Enter value for $column (primary key): "
                read primaryKeyValue

                # Check for empty value
                if [ -z "$primaryKeyValue" ]; then
                    echo "Primary key value cannot be empty. Please enter a value."
                    continue
                fi

                # Check for duplicate primary key values
                if grep -q "^$primaryKeyValue|" "$tablePath/data"; then
                    echo "Duplicate primary key value. Please enter a unique value."
                else
                    values+=("$primaryKeyValue")

                    # Save value to the column-specific list file
                    echo "$primaryKeyValue" >> "$tablePath/${column}_list"

                    break
                fi
            done
        else
            while true; do
                echo -n "Enter value for $column: "
                read value

                case $columnType in
                    "int")
                        if [[ ! $value =~ ^[0-9]+$ ]]; then
                            echo "Invalid input. Please enter an integer."
                            continue
                        fi
                        ;;
                    "str")
                        if [[ ! "$value" =~ ^[a-zA-Z]+$ ]]; then
                            echo "Invalid input. Please enter letters only."
                            continue
                        fi
                        ;;
                    "bool")
                        if [[ $value != "0" && $value != "1" ]]; then
                            echo "Invalid input. Please enter 0 or 1."
                            continue
                        fi
                        ;;
                esac

                values+=("$value")

                # Save value to the column-specific list file
                echo "$value" >> "$tablePath/${column}_list"

                break
            done
        fi
    done

    # Combine values into a '|' separated string
    valuesString=$(
        IFS='|'
        echo "${values[*]}"
    )

    # Append values to the data file
    echo "$valuesString" >>"$tablePath/data"

    echo "Values inserted successfully into table '$tableName'."
    break
    ;;


                *)
                                    zenity --info --text="Invalid option. Aborting insert operation."
                return
                ;;
        esac
    else
        zenity --info --text="Table '$tableName' not found in the current database."
    fi
} # End insertIntoTable function


# Function to select from a table
function selectFromTable() {
    echo "selectFromTable function is called."

    if [ -z "$currentDb" ]; then
        echo "No database selected. Please connect to a database first."
        return
    fi

    echo "Tables in the current database:"

    # List only directories (tables), not regular files
    for table in "$currentDb"/*; do
        if [ -d "$table" ]; then
            echo "- $(basename "$table")"
        fi
    done

    echo -n "Enter the table name to select from: "
    read tableName

    if [ -z "$tableName" ]; then
        echo "Table name cannot be empty. Aborting insert operation."
        return
    fi

    tablePath="$currentDb/$tableName"

    if [ -e "$tablePath" ]; then
        # Display column names with indices
        echo "Columns in table '$tableName':"
        columnIndex=0
        for colFile in "$tablePath"/*_list; do
            colName=$(basename "${colFile%_list}")
            echo "$columnIndex - $colName"
            ((columnIndex++))
        done

        # Prompt user for column selection
        read -p "Enter the column name to select: " selectedColumn

        # Validate selected column name
        if [ ! -e "$tablePath/${selectedColumn}_list" ]; then
            echo "Invalid column name. Please enter a valid column name."
            return
        fi

        # Read values from the corresponding list file
        listFilePath="$tablePath/${selectedColumn}_list"

        echo "Values for column '$selectedColumn':"
        cat "$listFilePath"

    else
        echo "Table '$tableName' not found in the current database."
    fi
} # End selectFromTable function




# Function to delete a specific row from a table
function deleteFromTable() {
    echo "deleteFromTable function is called."

    if [ -z "$currentDb" ]; then
        echo "No database selected. Please connect to a database first."
        return
    fi

    echo "Tables in the current database:"

    # List only directories (tables), not regular files
    for table in "$currentDb"/*; do
        if [ -d "$table" ]; then
            echo "- $(basename "$table")"
        fi
    done

    echo -n "Enter the table name to delete from: "
    read tableName

    if [ -z "$tableName" ]; then
        echo "Table name cannot be empty. Aborting delete operation."
        return
    fi

    tablePath="$currentDb/$tableName"

    if [ -d "$tablePath" ]; then
        echo "Do you want to delete a row?"
        select option in "Delete Row"; do
            case $option in
                "Delete Row")
                    echo -n "Enter the primary key value of the row to delete: "
                    read primaryKeyValue

                    if [ -z "$primaryKeyValue" ]; then
                        echo "Primary key value cannot be empty. Aborting delete operation."
                        return
                    fi

                    # Check if the primary key value exists in the data file
                    if grep -q "^$primaryKeyValue|" "$tablePath/data"; then
                        # Delete the row with the specified primary key value
                        sed -i "/^$primaryKeyValue|/d" "$tablePath/data"
                        echo "Row with primary key value '$primaryKeyValue' deleted successfully."
                    else
                        echo "Row with primary key value '$primaryKeyValue' not found."
                    fi
                    break
                    ;;

                *)
                    echo "Invalid option. Please select again."
                    ;;
            esac
        done
    else
        echo "Table '$tableName' not found in the current database."
    fi
}





# Function to update a table
function updateTable() {
    if [ -z "$currentDb" ]; then
        echo "No database selected. Please connect to a database first."
        return
    fi

    echo "Tables in the current database:"
    for table in "$currentDb"/*; do
        if [ -d "$table" ]; then
            echo "- $(basename "$table")"
        fi
    done

    read -p "Enter the table name to update: " tableName

    if [ -z "$tableName" ]; then
        echo "Table name cannot be empty. Aborting update operation."
        return
    fi

    tablePath="$currentDb/$tableName"

    if [ ! -d "$tablePath" ]; then
        echo "Table '$tableName' not found in the current database."
        return
    fi

    metadataFilePath="$tablePath/metadata"
    dataFile="$tablePath/data"

    if [ ! -f "$metadataFilePath" ] || [ ! -f "$dataFile" ]; then
        echo "Invalid table structure. Metadata or data files are missing."
        return
    fi

    # Read column names from the first line of the data file
    columns=$(head -n 1 "$dataFile")

    # Display column names
    echo "Columns in table '$tableName':"
    IFS='|' read -ra columnArray <<<"$columns"
    for ((i = 0; i < ${#columnArray[@]}; i++)); do
        echo "$((i + 1)) - ${columnArray[$i]}"
    done

    # Prompt user for column name to update
    read -p "Enter the column name to update: " columnName

    # Check if the column name is valid
    if [[ ! " ${columnArray[@]} " =~ " $columnName " ]]; then
        echo "Invalid column name. Aborting update operation."
        return
    fi

    # Prompt user for value to update
    read -p "Enter the new value for the column '$columnName': " newValue

    # Get the index of the specified column
    colIndex=$(echo "${columnArray[@]}" | awk -v columnName="$columnName" '{for(i=1;i<=NF;i++) if($i==columnName) print i}')

    # Read column names, datatypes, and primary key info from metadata file
    IFS='|' read -ra metadataColumns <<<"$(awk -v colIndex="$colIndex" -F'|' -v columnName="$columnName" '$1 == columnName {print $2 "|" $3; exit}' "$metadataFilePath")"

    # Get the datatype of the specified column
    dataType=${metadataColumns[0]}

    # echo "==========="
    # echo "col  number : $colIndex"
    # echo "col datatype: $dataType"
    # echo "==========="

    # Validate the new value based on the column's datatype
    case $dataType in
    "int")
        # Validation for integer datatype
        if ! [[ "$newValue" =~ ^[0-9]+$ ]]; then
            echo "Invalid input. The new value must be an integer."
            return
        fi
        ;;
    "str")
        # Validation for string datatype
        if [[ "$newValue" =~ "|" ]]; then
            echo "Invalid input. The new value for a string type cannot contain '|'."
            return
        fi
        ;;
    "boolean")
        # Validation for boolean datatype
        if [[ "$newValue" != '1' && "$newValue" != '0' ]]; then
            echo "Invalid input. The new value must be '0' or '1' for boolean type."
            return
        fi
        ;;
    *)
        echo "Unknown datatype in metadata. Aborting update operation."
        return
        ;;
    esac

    # If the column is a primary key, check if the new value is unique
    isPrimary=${metadataColumns[1]}
    if [ "$isPrimary" == "yes" ]; then
        uniqueCheck=$(awk -v colIndex="$colIndex" -v newValue="$newValue" -F'|' 'NR>1 {if ($colIndex == newValue) print "notUnique"}' "$dataFile")
        if [ "$uniqueCheck" == "notUnique" ]; then
            echo "Error: The new value must be unique for the primary key column '$columnName'."
            return
        fi
    fi

    # Prompt user for the condition
    read -p "Do you want to update a specific row based on a condition? (yes/no): " updateCondition

    if [ "$updateCondition" == "yes" ]; then
        read -p "Do you want a 'WHERE' condition? (yes/no): " whereCondition

        if [ "$whereCondition" == "yes" ]; then
            # Prompt user for column of where condition
            read -p "Enter the Column of where condition: " columnWhere
            # Prompt user for value of where condition
            read -p "Enter the Value of where condition: " valueWhere
            # Get the index of the specified column
            colWhereIndex=$(echo "${columnArray[@]}" | awk -v columnWhere="$columnWhere" '{for(i=1;i<=NF;i++) if($i==columnWhere) print i}')
            # Perform the update using awk
            awk -v colWhereIndex="$colWhereIndex" -v valueWhere="$valueWhere" -v colIndex="$colIndex" -v newValue="$newValue" 'BEGIN {FS=OFS="|"} {if (NR == 1) {print; next} else if ($colWhereIndex == valueWhere) $colIndex = newValue; print}' "$dataFile" >"$dataFile.tmp"

        elif [ "$whereCondition" == "no" ]; then
            # placeholder
            echo "other conditions implementation still under-work..."
        fi

    elif [ "$updateCondition" == "no" ]; then
        # Update all rows
        echo "Updating all rows"
        awk -v colIndex="$colIndex" -v newValue="$newValue" 'BEGIN {FS=OFS="|"} {if (NR == 1) {print; next} else $colIndex = newValue; print}' "$dataFile" >"$dataFile.tmp"
    fi

    # Safely move the temporary file to the original file's location
    if mv "$dataFile.tmp" "$dataFile"; then
        echo "Update in table '$tableName' completed successfully."
    else
        echo "Error during update. Rolling back changes."
        rm "$dataFile.tmp"
    fi
}

# ================================<< End of (( Functions of DBMS )) >>================================

# ================================<< Start of (( Main Menu )) >>================================
function mainMenu() {
    while true; do
        choice=$(zenity --list \
                        --title="Main Menu" \
                        --text="Choose an option:" \
                        --column="Options" \
                        "Create Database" \
                        "List Databases" \
                        "Connect To Database" \
                        "Drop Database" \
                        "Quit")

        case $choice in
            "Create Database")
                createDatabase
                ;;
            "List Databases")
                listDatabase
                ;;
            "Connect To Database")
                connectToDatabase
                runSubMenu
                ;;
            "Drop Database")
                dropDatabase
                ;;
            "Quit")
                exit
                ;;
            *)
                zenity --error --text="Invalid option. Please try again."
                ;;
        esac
    done
}

# ================================<< Start of (( SubMenu )) >>================================
function runSubMenu() {
    while [ -n "$currentDb" ]; do
        choice=$(zenity --list \
                        --title="Sub Menu" \
                        --text="Choose an option:" \
                        --column="Options" \
                        "Create Table" \
                        "List Tables" \
                        "Drop Table" \
                        "Insert Into Table" \
                        "Select From Table" \
                        "Delete From Table" \
                        "Update Table" \
                        "Back TO Main Menu" \
                        "Quit")

        case $choice in
            "Create Table")
                createTable
                ;;
            "List Tables")
                listTable
                ;;
            "Drop Table")
                dropTable
                ;;
            "Insert Into Table")
                insertIntoTable
                ;;
            "Select From Table")
                selectFromTable
                ;;
            "Delete From Table")
                deleteFromTable
                ;;
            "Update Table")
                updateTable
                ;;
            "Back TO Main Menu")
                currentDb=""
                return
                ;;
            "Quit")
                exit
                ;;
            *)
                zenity --error --text="Invalid option. Please try again."
                ;;
        esac
    done
}

# ================================<< (( CALLING MAIN FUNCTION TO RUN THE PROGRAM )) >>================================
mainMenu
