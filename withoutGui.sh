    #! /usr/bin/bash
    shopt -s extglob
    export LC_COLLATE=C
# ANSI escape codes for colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color


    echo -e "${RED}WELCOME TO ${GREEN}MY ${YELLOW}DATABASE ${BLUE}MANAGEMENT ${PURPLE}SYSTEM ${NC}"

# Reset font size to default
tput cvvis   # Make the cursor visible again
tput sgr0    # Reset text attributes
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
        read -p "Enter the database name: " dbName
        dbPath="$DATABASE_DIR/$dbName"
        if [[ ! $dbName =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo "Invalid database name. Database names must start with a letter or underscore and only contain letters, numbers, and underscores."
        elif [ -d "$dbPath" ]; then
            echo "Database '$dbName' already exists."
        else
            mkdir "$dbPath"

            echo -e "${RED}Database '$dbName' ${GREEN}created ${YELLOW}successfully. ${NC}"
        fi
    }

    # Function to list all databases
    function listDatabase() {
        if [ -z "$(ls $DATABASE_DIR)" ]; then
            echo "No Databases found ."
            return
        fi
                    echo -e "${RED}Available ${GREEN}databases: ${NC}"


        # for db in "$DATABASE_DIR"/*/; do
        #     echo "- $(basename "${db%/}")"
        # done

        for db in "$DATABASE_DIR"/*; do
            if [ -d "$db" ]; then
                echo "- $(basename "$db")"
            fi
        done
    }

    # Function to connect to a database
    function connectToDatabase() {
        read -p "Enter the database name: " dbName
        dbPath="$DATABASE_DIR/$dbName"
        if [ -z "$dbName" ]; then
            echo "Database name cannot be empty. Aborting Database connect."
        elif [ -d "$dbPath" ]; then
            currentDb="$dbPath"
                                echo -e "${RED}Connected ${GREEN}to ${YELLOW} database '$dbName' ${NC}"

            runSubMenu
        else
            echo "Database '$dbName' not found."
        fi
    }

    # Function to drop a database
    function dropDatabase() {
        read -p "Enter the database name to drop: " dbName
        dbPath="$DATABASE_DIR/$dbName"
        if [ -z "$dbName" ]; then
            echo "Database name cannot be empty. Aborting Database drop."
        elif [ -d "$dbPath" ]; then
            rm -r "$dbPath"
            
            echo -e "${RED}Database '$dbName' ${GREEN}dropped ${YELLOW}successfully. ${NC}"
        else
            echo "Database '$dbName' not found."
        fi
    }







    # ================================================================
    # ================================================================





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
# Function to create a new table
function createTable() {
            echo -e "${RED}createTable ${GREEN}function ${YELLOW}called. ${NC}"


    while true; do
        # Input table name
        read -p "Enter table name: " tableName

        # Validate table name
        if validateName "$tableName"; then

            # Check if table already exists
            if [[ -d "$currentDb/$tableName" ]]; then
                echo "Table $tableName already exists."
            else
                # Input number of columns
                while true; do
                    read -p "Enter number of columns: " columns

                    # Check if the input is a positive integer
                    if [[ $columns =~ ^[1-9][0-9]*$ ]]; then
                        break
                    else
                        echo "Invalid input. Please enter a valid positive integer for the number of columns."
                    fi
                done

                # Create table directory
                mkdir -p "$currentDb/$tableName" || { echo "Error creating table directory."; return; }

                # Create metadata file for table
                touch "$currentDb/$tableName/metadata" || { echo "Error creating metadata file."; return; }

                # Create data file for table
                touch "$currentDb/$tableName/data" || { echo "Error creating data file."; return; }

                # Input primary key column
                while true; do
                    # Input column name
                    read -p "Enter Primary Key Column Name: " primaryKeyColName

                    # Check if the column name is already used
                    if validateName "$primaryKeyColName" && ! grep -q "^$primaryKeyColName|" "$currentDb/$tableName/metadata"; then
                        # Input data type for primary key
                        while true; do
                            read -p "Select Data Type for $primaryKeyColName (int/str/boolean): " primaryKeyDataType

                            # Check if the entered data type is valid
                            case $primaryKeyDataType in
                            "int" | "str" | "boolean")
                                break # Break out of the loop if the input is valid
                                ;;
                            *)
                                echo "Invalid data type. Please enter 'int', 'str', or 'boolean'."
                                ;;
                            esac
                        done

                        # Append primary key column info to metadata file
                        echo "$primaryKeyColName|$primaryKeyDataType|yes" >>"$currentDb/$tableName/metadata"
                        break  # Break the loop if the primary key column details are valid
                    else
                        echo "Name validation error. Please enter a valid and non-duplicated name for the primary key column."
                    fi
                done

                # Loop through remaining columns
                columnNames=("$primaryKeyColName")  # Initialize with the primary key column
                for ((i = 2; i <= columns; i++)); do
                    while true; do
                        # Input column name
                        read -p "Enter Column $i Name: " colName

                        # Check if the column name is already used
                        if validateName "$colName" && ! grep -q "^$colName|" "$currentDb/$tableName/metadata"; then
                            columnNames+=("$colName")

                            # Input data type
                            while true; do
                                read -p "Select Data Type for $colName (int/str/boolean): " datatype

                                # Check if the entered data type is valid
                                case $datatype in
                                "int" | "str" | "boolean")
                                    break # Break out of the loop if the input is valid
                                    ;;
                                *)
                                    echo "Invalid data type. Please enter 'int', 'str', or 'boolean'."
                                    ;;
                                esac
                            done

                            # Append column info to metadata file
                            echo "$colName|$datatype|no" >>"$currentDb/$tableName/metadata"
                            break  # Break the loop if the column details are valid
                        else
                            echo "Name validation error. Please enter a valid and non-duplicated name for Column $i."
                        fi
                    done
                done

                # Store column names in the first row of the data file with "|"
                echo "${columnNames[*]}" | tr ' ' '|' >>"$currentDb/$tableName/data"

                # Append "|" to the first line of the data file
                sed -i '1s/$/|/' "$currentDb/$tableName/data"

                echo "Table $tableName created successfully."
                break  # Break the loop if the table is created successfully
            fi
        else
            echo "Name validation error. Please enter a valid name."
        fi
    done
} # End Create Table function




# Function to list all tables in the current database
function listTable() {

            echo -e "${RED}listeTable ${GREEN}function ${YELLOW}called. ${NC}"
    if [ -z "$currentDb" ]; then
        echo "No database selected. Please connect to a database first."
        return
    fi

    # Capture the absolute path of the current database directory
    currentDbPath=$(realpath "$currentDb")

    # Check if the database is empty
    if [ -z "$(ls -A "$currentDbPath")" ]; then
        echo "No tables found in the current database."
        return
    fi

    echo "Tables in the current database:"

    for table in "$currentDbPath"/*; do
        if [ -d "$table" ]; then
            echo "- $(basename "$table")"
        fi
    done
} # End listTable function.

# Function to drop a table from the specified database
function dropTable() {

            echo -e "${RED}dropTable ${GREEN}function ${YELLOW}called. ${NC}"
    if [ -z "$currentDb" ]; then
        echo "No database selected. Please connect to a database first."
        return
    fi

    # Capture the absolute path of the current database directory
    currentDbPath=$(realpath "$currentDb")

    echo "Tables in the current database:"

    # List only directories (tables), not regular files
    for table in "$currentDbPath"/*; do
        if [ -d "$table" ]; then
            echo "- $(basename "$table")"
        fi
    done

    while true; do
        echo -n "Enter the table name to drop: "
        read tableName

        if [ -z "$tableName" ]; then
            echo "Table name cannot be empty. Please enter a valid table name."
        else
            tablePath="$currentDbPath/$tableName"

            if [ -d "$tablePath" ]; then
                # Confirm before dropping the table
                echo -n "Are you sure you want to drop table '$tableName'? (yes/no): "
                read confirmation

                case $confirmation in
                    [Yy][Ee][Ss])
                        rm -r "$tablePath" || { echo "Error dropping table '$tableName'."; return; }
                        echo "Table '$tableName' dropped successfully."
                        break  # Exit the loop if the table is dropped successfully
                        ;;
                    *)
                        echo "Table drop aborted."
                        break  # Exit the loop if the user decides not to drop the table
                        ;;
                esac
            else
                echo "Table '$tableName' not found in the current database. Please enter a valid table name."
            fi
        fi
    done
} # End dropTable function.




# Function to insert into a table
function insertIntoTable() {

            echo -e "${RED}insertIntoTable ${GREEN}function ${YELLOW}called. ${NC}"
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

    echo -n "Enter the table name to insert into: "
    read tableName

    if [ -z "$tableName" ]; then
        echo "Table name cannot be empty. Aborting insert operation."
        return
    fi

    tablePath="$currentDb/$tableName"

    if [ -d "$tablePath" ]; then
        echo "Do you want to insert columns or data into columns?"
        select option in "Insert Columns" "Insert Data"; do
            case $option in
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

                    # Combine existing columns and new columns
                    allColumns="${existingColumns}${columnNames[@]}|"

                    # Temporarily save the rest of the file excluding the first line
                    tail -n +2 "$tablePath/data" > "$tablePath/data_temp"

                    # Overwrite the first line of the data file with the combined column names
                    echo "$allColumns" > "$tablePath/data"

                    # Append the rest of the file back
                    cat "$tablePath/data_temp" >> "$tablePath/data"

                    # Remove the temporary file
                    rm "$tablePath/data_temp"

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

                                # Check for correct data type
                                case $columnType in
                                    "int")
                                        if ! [[ "$primaryKeyValue" =~ ^[1-9][0-9]*$ ]]; then
                                            echo "Invalid input. Please enter an integer."
                                            continue
                                        fi
                                        ;;
                                    "str")
                                        if ! [[ "$primaryKeyValue" =~ ^[a-zA-Z]+$ ]]; then
                                            echo "Invalid input. Please enter letters only."
                                            continue
                                        fi
                                        ;;
                                    "bool")
                                        if [[ "$primaryKeyValue" != "0" && "$primaryKeyValue" != "1" ]]; then
                                            echo "Invalid input. Please enter 0 or 1."
                                            continue
                                        fi
                                        ;;
                                esac

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
                                        if ! [[ "$value" =~ ^[1-9][0-9]*$ ]]; then
                                            echo "Invalid input. Please enter an integer."
                                            continue
                                        fi
                                        ;;
                                    "str")
                                        if ! [[ "$value" =~ ^[a-zA-Z]+$ ]]; then
                                            echo "Invalid input. Please enter letters only."
                                            continue
                                        fi
                                        ;;
                                    "bool")
                                        if [[ "$value" != "0" && "$value" != "1" ]]; then
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
                    echo "Invalid option. Please select again."
                    ;;
            esac
        done
    else
        echo "Table '$tableName' not found in the current database."
    fi
} # End insertIntoTable function









    # ================================================================
    # ================================================================









    # Function to select from a table
    function selectFromTable() {
    
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

    read -p "Enter the table name to select from: " tableName

    if [ -z "$tableName" ]; then
        echo "Table name cannot be empty. Aborting select operation."
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

    # Check if there are rows in the data file after the first line
    rowCount=$(awk 'NR > 1 { count++ } END { print count }' "$dataFile")
    if [ "$rowCount" -eq 0 ]; then
        echo "The table '$tableName' is empty. No data to update."
        return
    fi




    # Display column names
    echo "Columns in table '$tableName':"
    IFS='|' read -ra columnArray <<<"$columns"
    for ((i = 0; i < ${#columnArray[@]}; i++)); do
        echo "$((i + 1)) - ${columnArray[$i]}"
    done




    read -p "Do you want to select a specific row based on a 'WHERE' condition? (yes/no): " selectCondition

    if [ "$selectCondition" == "yes" ]; then
        read -p "Enter the column name for the 'WHERE' condition: " columnWhere

        if [ -z "$columnWhere" ]; then
            echo "Column name cannot be empty. Aborting select operation."
            return
        fi

        # Check if the specified column exists
        if [[ ! " ${columnArray[@]} " =~ " $columnWhere " ]]; then
            echo "Error: The specified column name '$columnWhere' does not exist. Aborting select operation."
            return
        fi

        read -p "Enter the value for the 'WHERE' condition: " valueWhere

        if [ -z "$valueWhere" ]; then
            echo "Value cannot be empty. Aborting select operation."
            return
        fi

        # Get the index of the specified column for WHERE condition
        colWhereIndex=$(echo "${columnArray[@]}" | awk -v columnWhere="$columnWhere" '{for(i=1;i<=NF;i++) if($i==columnWhere) print i}')
# Perform the selection using awk
awk -v colWhereIndex="$colWhereIndex" -v valueWhere="$valueWhere" 'BEGIN {FS=OFS="|"; found=0} {if (NR == 1) {print; next} else if ($colWhereIndex == valueWhere) {print; found=1}} END {if (found != 1) print "No rows selected"}' "$dataFile"

# Check if there were no matching rows
noRowsSelected=$(awk 'END {print $0}' "$dataFile")

if [ "$noRowsSelected" == "No rows selected" ]; then
    echo "No rows selected."
    rm "$dataFile.tmp"
    return
fi
    elif [ "$selectCondition" == "no" ]; then
        awk '{if (NR >= 1) print}' "$dataFile"
    else
        echo "Invalid input. Aborting select operation."
        return
    fi
    } # End selectFromTable function








    # Function to delete from a table
    function deleteFromTable() {
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

    read -p "Enter the table name to delete from: " tableName

    if [ -z "$tableName" ]; then
        echo "Table name cannot be empty. Aborting delete operation."
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

    # Check if there are rows in the data file after the first line
    rowCount=$(awk 'NR > 1 { count++ } END { print count }' "$dataFile")
    if [ "$rowCount" -eq 0 ]; then
        echo "The table '$tableName' is empty. No data to delete."
        return
    fi

    echo "Content in the table '$tableName':"
    awk '{if (NR >= 1) print}' "$dataFile"

    read -p "Do you want to delete specific rows based on a 'WHERE' condition '(yes) for ok' / '(no) for delete all'? (yes/no): " deleteCondition

    if [ "$deleteCondition" == "yes" ]; then
        read -p "Enter the column name for the 'WHERE' condition: " columnWhere

        if [ -z "$columnWhere" ]; then
            echo "Column name cannot be empty. Aborting delete operation."
            return
        fi

        # Check if the specified column exists
        if [[ ! " ${columnArray[@]} " =~ " $columnWhere " ]]; then
            echo "Error: The specified column name '$columnWhere' does not exist. Aborting delete operation."
            return
        fi

        read -p "Enter the value for the 'WHERE' condition: " valueWhere

        if [ -z "$valueWhere" ]; then
            echo "Value cannot be empty. Aborting delete operation."
            return
        fi

        # Get the index of the specified column for WHERE condition
        colWhereIndex=$(echo "${columnArray[@]}" | awk -v columnWhere="$columnWhere" '{for(i=1;i<=NF;i++) if($i==columnWhere) print i}')
awk -v colWhereIndex="$colWhereIndex" -v valueWhere="$valueWhere" 'BEGIN {FS=OFS="|"} {if (NR == 1 || $colWhereIndex != valueWhere) print}' "$dataFile" > "$dataFile.tmp"




    elif [ "$deleteCondition" == "no" ]; then
        # Keep only the first line (column names) in the data file
        echo "$columns" > "$dataFile.tmp"
    else
        echo "Invalid input. Aborting delete operation."
        return
    fi

    # Safely move the temporary file to the original file's location
    if mv "$dataFile.tmp" "$dataFile"; then
        echo "Deletion from table '$tableName' completed successfully."
    else
        echo "Error during deletion. Rolling back changes."
        rm "$dataFile.tmp"
    fi
    } # End deleteFromTable function





















    # ================================<< Start of (( update Function )) >>================================
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

    # Check if there are rows in the data file after the first line
    rowCount=$(awk 'NR > 1 { count++ } END { print count }' "$dataFile")
    if [ "$rowCount" -eq 0 ]; then
        echo "The table '$tableName' is empty. No data to update."
        return
    fi




    # Display column names
    echo "Columns in table '$tableName':"
    IFS='|' read -ra columnArray <<<"$columns"
    for ((i = 0; i < ${#columnArray[@]}; i++)); do
        echo "$((i + 1)) - ${columnArray[$i]}"
    done

    # Prompt user for column name to update
    read -p "Enter the column name to update: " columnName

    # check if the column name is empty
    if [ -z "$columnWhere" ]; then
        echo "Column name cannot be empty. Aborting update operation."
        return
    fi

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
    read -p "Do you want to update a specific row based on a 'WHERE' condition? (yes/no): " updateCondition

    if [ "$updateCondition" == "yes" ]; then
        # Prompt user for column of where condition
        read -p "Enter the Column name of where condition: " columnWhere

        # check if the column name is empty
        if [ -z "$columnWhere" ]; then
            echo "Column name cannot be empty. Aborting update operation."
            return
        fi

        # Check if the specified column exists
        if [[ ! " ${columnArray[@]} " =~ " $columnWhere " ]]; then
            echo "Error: The specified column name '$columnWhere' does not exist. Aborting update operation."
            return
        fi

        # Prompt user for value of where condition
        read -p "Enter the Value of where condition: " valueWhere

        # Get the index of the specified column for WHERE condition
        colWhereIndex=$(echo "${columnArray[@]}" | awk -v columnWhere="$columnWhere" '{for(i=1;i<=NF;i++) if($i==columnWhere) print i}')






        # Check if the chosen columnName is a primary key
        if [ "$isPrimary" == "yes" ]; then
            # Check if the new value for the primary key will be unique if the update done.
            countOccurrences=$(awk -v colWhereIndex="$colWhereIndex" -v valueWhere="$valueWhere" -F'|' 'NR>1 {if ($colWhereIndex == valueWhere) count++} END {print count}' "$dataFile")
            if [ "$countOccurrences" -gt 1 ]; then
                echo "Error: The new value for the primary key column '$columnName' must be unique. Aborting update operation."
                return
            fi
        fi

# Perform the update using awk
awk -v colWhereIndex="$colWhereIndex" -v valueWhere="$valueWhere" -v colIndex="$colIndex" -v newValue="$newValue" 'BEGIN {FS=OFS="|"} {if (NR == 1) {print; next} else if ($colWhereIndex == valueWhere) {$colIndex = newValue; updated = 1} print} END {if (updated != 1) print "No rows selected for update"}' "$dataFile" >"$dataFile.tmp"

# Check if there were no matching rows
noRowsSelected=$(awk 'END {print $0}' "$dataFile.tmp")

if [ "$noRowsSelected" == "No rows selected for update" ]; then
    echo "No rows selected for update."
    rm "$dataFile.tmp"
    return
fi

elif [ "$updateCondition" == "no" ]; then
    # Check if the chosen columnName is a primary key
    isPrimary=${metadataColumns[1]}
    if [ "$isPrimary" == "yes" ]; then
        rowCount=$(awk 'NR > 1 { count++ } END { print count }' "$dataFile")
        if [ "$rowCount" -gt 1 ]; then
            echo "Error: The new value for the primary key column '$columnName' must be unique. Aborting update operation."
            return
        fi
    fi

    # Update all rows
    echo "Updating all rows"
    awk -v colIndex="$colIndex" -v newValue="$newValue" 'BEGIN {FS=OFS="|"} {if (NR == 1) {print; next} else $colIndex = newValue; print}' "$dataFile" >"$dataFile.tmp"

    # Check if there were no matching rows
    noRowsSelected=$(awk 'END {print $0}' "$dataFile.tmp")

    if [ "$noRowsSelected" == "No rows selected for update" ]; then
        echo "No rows selected for update."
        rm "$dataFile.tmp"
        return
    fi
else
    echo "Invalid input. Aborting update operation."
    return
fi

# Safely move the temporary file to the original file's location
if mv "$dataFile.tmp" "$dataFile"; then
    echo "Update in table '$tableName' completed successfully."
else
    echo "Error during update. Rolling back changes."
    rm "$dataFile.tmp"
fi
}

    # ================================<< End of (( update Function )) >>================================

    

















    # ================================<< End of (( Functions of DBMS )) >>================================

    # ================================<< Start of (( Main Menu )) >>================================

    # Function to runMainMenu a table
    function runMainMenu() {
        while true; do
            PS3="Choose an option: "
            options=("Create Database" "List Databases" "Connect To Database" "Drop Database" "Quit")
            select opt in "${options[@]}"; do
                case $opt in
                "Create Database")
                    createDatabase
                    break
                    ;;
                "List Databases")
                    listDatabase
                    break
                    ;;
                "Connect To Database")
                    connectToDatabase
                    break
                    ;;
                "Drop Database")
                    dropDatabase
                    break
                    ;;
                "Quit")
                    exit
                    ;;
                *)
                    echo "Invalid option. Please try again."
                    ;;
                esac
            done
        done
    }

    # ================================<< End of (( Main Menu )) >>================================

    # ================================<< Start of (( SubMenu )) >>================================

    # Function to runSubMenu a table
    function runSubMenu() {
        while [ -n "$currentDb" ]; do
            PS3="Choose an option: "
            options=("Create Table" "List Tables" "Drop Table" "Insert Into Table" "Select From Table" "Delete From Table" "Update Table" "Back TO Main Menu" "Quit")
            select opt in "${options[@]}"; do
                case $opt in
                "Create Table")
                    createTable
                    break
                    ;;
                "List Tables")
                    listTable
                    break
                    ;;
                "Drop Table")
                    dropTable
                    break
                    ;;
                "Insert Into Table")
                    insertIntoTable
                    break
                    ;;
                "Select From Table")
                    selectFromTable
                    break
                    ;;
                "Delete From Table")
                    deleteFromTable
                    break
                    ;;
                "Update Table")
                    updateTable
                    break
                    ;;
                "Back TO Main Menu")
                    currentDb=""
                    return
                    ;;
                "Quit")
                    exit
                    ;;
                *)
                    echo "Invalid option. Please try again."
                    ;;
                esac
            done
        done
    }

    # ================================<< End of (( SubMenu )) >>================================

    # ================================<< (( CALLING MAIN FUNCTION TO RUN THE PROGRAM )) >>================================

    runMainMenu
