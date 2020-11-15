import RPi.GPIO as GPIO
from time import sleep

button_state = "OFF"
button_pin = 16
led_pin = 18

def button_callback(channel):
    #print("BUTTON PRESS")
    global button_state
    global led_pin

    if button_state == "OFF":
        print("LIGHT ON")
        GPIO.output(led_pin, GPIO.HIGH)
        button_state = "ON"
    else:
        print("LIGHT OFF")
        GPIO.output(led_pin, GPIO.LOW)
        button_state = "OFF"

#callback_lambda = lambda x: button_callback(x, button_state)


# initialize
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM) # use physical pin numbers
# set button_pin to be input and set inital value to be pulled low
GPIO.setup(button_pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
# set LED output
GPIO.setup(led_pin, GPIO.OUT)

# start up sequence
GPIO.output(led_pin, GPIO.HIGH)
sleep(1)
GPIO.output(led_pin, GPIO.LOW)
sleep(1)

# setup event on pin 10 rising edge
GPIO.add_event_detect(button_pin, GPIO.RISING, callback=button_callback, bouncetime=200)

message = input("Press enter to quit \n\n") # run until someone presses enter
GPIO.cleanup() # cleanup
