#!/bin/bash

# ctrl+s ---> save the file after making changes
# Author :: Yeswanth
# Team :: DevOps

# run the script as sh <script file> if root user or sudo sh <script file> if normal user with root permissions

LOG_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

mkdir -p $LOG_FOLDER



USERID=$(id -u)                     # gets the user id of the user running the script; root - 0; if the script is executed with sudo it gives 0

# colors
R="\e[31m"      # red
G="\e[32m"      # green
Y="\e[33m"      # yellow
B="\e[34m"
N="\e[0m"       # normal or no color


VALIDATE(){                 # function to validate the installation
    if [ $1 -ne 0 ]
    then
        echo -e "$2.....$R failed $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2.....$G success $N" | tee -a $LOG_FILE
    fi
}

INSTALL(){                      # function to install the given package if not installed already
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is $B not installed $N..... proceeding to install it" | tee -a $LOG_FILE
        dnf install $2 -y &>>$LOG_FILE
        VALIDATE $? "$2 installation"    
    else
        echo -e "$2 is $Y already installed $N....... nothing to do" | tee -a $LOG_FILE
    fi
}

echo "$0 started executing at: $(date)" | tee -a $LOG_FILE


if [ $USERID -ne 0 ]
then
    echo -e "$R please run the script with root privileges $N" | tee -a $LOG_FILE
    exit 1
fi


dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling Nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "nodejs installation"


id expense &>>$LOG_FILE

if [ $? -ne 0 ]
then
    echo -e "user with name expense does not exist....... $B adding the user $N" | tee -a $LOG_FILE
    useradd expense &>>$LOG_FILE
    VALIDATE $? "adding user expense"
else
    echo -e "user with name expense already exist........ $Y skipping $N" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "downloading the backend application code"

cd /app

rm -rf /app/*

unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "extraction of backend application code"


npm install &>>$LOG_FILE
VALIDATE $? "npm installation"

cp /home/ec2-user/3tier-shell/backend.service /etc/systemd/system/backend.service




dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "mysql client installation"

mysql -h mysql.sprojex.in -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "loading schema/database"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "enabling backend service"

systemctl start backend &>>$LOG_FILE
VALIDATE $? "starting backend service"
