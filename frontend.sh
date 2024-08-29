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


dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "nginx installation"


rm -rf /usr/share/nginx/html/*

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATE $? "downloading the frontend application code"

cd /usr/share/nginx/html

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "extraction of frontend application code"

cp /home/ec2-user/3tier-shell/frontend.conf /etc/nginx/default.d/frontend.conf

cp /home/ec2-user/3tier-shell/frontend-upstream.conf /etc/nginx/conf.d/frontend-upstream.conf

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enabling nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "starting nginx"
