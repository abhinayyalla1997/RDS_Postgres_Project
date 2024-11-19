# Automation Script for User &amp; Database Management in AWS RDS PostgreSQL with Dynamic Value Passing

## Overview
This project is an automation tool designed to manage PostgreSQL databases hosted on **AWS RDS**. The tool uses a series of Bash scripts to create databases, write to databases, and manage access control efficiently. By invoking a central `postgres` script, you can dynamically execute different operations based on specific commands, passing necessary parameters directly.

## Project Structure
The project consists of four Bash script files:

- **postgres:** The main script that invokes other scripts based on the command provided.
- **create.sh:** Script responsible for creating PostgreSQL users and databases in AWS RDS.
- **write.sh:** Script that writes data or executes SQL commands on the specified PostgreSQL database.
- **access.sh:** Script that manages access control and permissions for users in the PostgreSQL database.

## How It Works
The `postgres` script acts as a controller, invoking other scripts based on the command you provide. Each script is responsible for a specific function, such as creating databases, managing permissions, or writing data.

## Usage Examples

### Creating a Database/User:
To create a new PostgreSQL user or database:
```bash
./postgres create -e <db_endpoint> -P <postgres_user> -W <postgres_pass> -D <postgres_db> -n <db_name>"
```
This will invoke the `create.sh` script to create a new PostgreSQL user or database based on the input parameters.

### Managing Access:
To manage user access to the database, you can use the following command:
```bash
./postgres access -u <db_user> -p <db_password> -r <db_readonly_name> -e <db_endpoint> -P <postgres_user> -W <postgres_pass> -D <postgres_db> -A <admin_db>"
```
This will invoke the `access.sh` script to manage user access, passing the necessary RDS endpoint, username, password, database name, and permissions as parameters.

### Writing to Database:
To execute SQL commands or insert data into a PostgreSQL database:
```bash
./postgres write -u <db_user> -p <db_password> -n <db_name> -e <db_endpoint> -P <postgres_user> -W <postgres_pass> -D <postgres_db> -A <admin_db>"
```
This will invoke the `write.sh` script to write data or execute SQL commands in the specified PostgreSQL database.

### Revoking Public Role Access:
To revoke access from the public role for a PostgreSQL database:
```bash
./postgres public_role_info
```
This will invoke the `public_role_info.sh` script to revoke public role access from the database.

### Granting Table-Level Permissions:
To grant permissions to a specific table in the database:
```bash
./postgres table_adv
```
This will invoke the `table_adv.sh` script, allowing users to perform actions such as insert, update, and delete entries only within the specified table.

## Prerequisites
To use this project, you’ll need:
- **AWS RDS PostgreSQL:** An active AWS RDS instance running PostgreSQL.
- **Bash:** The scripts are written in Bash, so a Unix-based operating system like Ubuntu is recommended.
- **SQL Knowledge:** Understanding of SQL commands is necessary for writing and managing data.
- **Ubuntu:** The project was developed and tested on Ubuntu, it should work on any Unix-based system.

## Technologies Used
- **AWS RDS PostgreSQL:** The database management system used for hosting PostgreSQL databases in the cloud.
- **Bash Scripting:** Used to automate database creation, data management, and access control.
- **SQL Commands:** SQL is used within the scripts to interact with the PostgreSQL database.
- **Ubuntu:** The development environment where the scripts were created and tested.

## Getting Started

### Clone the Repository
```bash
git clone https://github.com/yourusername/repository-name.git
```
Ensure you have access to your AWS RDS PostgreSQL instance and the necessary credentials and endpoints.

### Modify the Scripts
Modify the scripts to fit your specific environment if necessary.

## Running the Script
To run the main `postgres` script, use the following format:
```bash
./postgres [command] [parameters]
```
### Available Commands:
- **create:** To create databases and users.
- **access:** To manage user access and permissions.
- **write:** To insert data or execute SQL commands.

### Available Scripts:
- **public_role_info:** To revoke public role access from the database.
- **table_adv:** To grant permissions to a specific table in the database.

if you want , u can add these scripts in postgress accordingly.

### Example Command:
To manage user access and permissions:
```bash
./postgres access -e "postgres-project.ap-south-1.rds.amazonaws.com" -W "password" -P "postgres99" -D "postgres" -n "invoke" -u "testing" -p "testing" -A "db_had_table"
```

## Contributing
Feel free to fork the repository and submit pull requests. Contributions are welcome!

Steps for contributing:
1. Fork the project.
2. Create your feature branch (`git checkout -b feature/new-feature`).
3. Commit your changes (`git commit -m 'Add new feature'`).
4. Push to the branch (`git push origin feature/new-feature`).
5. Open a pull request.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
