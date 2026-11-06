#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only --no-align -c"

# Escape single quotes for SQL strings
ESCAPE_SQL() {
  printf '%s' "$1" | sed "s/'/''/g"
}

# Display available services
SHOW_SERVICES() {
  echo -e "\n~~~~~ MY SALON ~~~~~"
  echo -e "\nWelcome to My Salon, how can I help you?\n"

  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id;")

  while IFS='|' read -r SERVICE_ID SERVICE_NAME
  do
    if [[ -n $SERVICE_ID ]]
    then
      echo "$SERVICE_ID) $SERVICE_NAME"
    fi
  done <<< "$SERVICES"
}

# Choose a valid service
while true
do
  SHOW_SERVICES

  echo -e "\nPlease enter a service ID:"
  read SERVICE_ID_SELECTED

  if [[ $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")

    if [[ -n $SERVICE_NAME ]]
    then
      break
    fi
  fi

  echo -e "\nI could not find that service. Please choose again."
done

# Ask for customer phone number
echo -e "\nWhat's your phone number?"
read CUSTOMER_PHONE

PHONE_SQL=$(ESCAPE_SQL "$CUSTOMER_PHONE")

# Check if customer exists
CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$PHONE_SQL';")

# Register new customer
if [[ -z $CUSTOMER_ID ]]
then
  echo -e "\nI don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME

  NAME_SQL=$(ESCAPE_SQL "$CUSTOMER_NAME")

  $PSQL "INSERT INTO customers (name, phone) VALUES ('$NAME_SQL', '$PHONE_SQL') ON CONFLICT (phone) DO NOTHING;" > /dev/null

  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$PHONE_SQL';")
fi

# Get customer's name
CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")

# Ask for appointment time
echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

TIME_SQL=$(ESCAPE_SQL "$SERVICE_TIME")

# Save appointment
INSERT_RESULT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$TIME_SQL') RETURNING appointment_id;") || exit 1

if [[ -n $INSERT_RESULT ]]
then
  echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
fi
