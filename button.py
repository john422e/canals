import RPi.GPIO as GPIO

def button_callback(channel):
    print("BUTTON PRESS")
    if button_state == "OFF":
        print("LIGHT ON")
        button_state = "ON"
    else:
        print("LIGHT OFF")
        button_state = "OFF"

button_state = "OFF"

button_pin = 36

# initialize
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BOARD) # use physical pin numbers
# set button_pin to be input and set inital value to be pulled low
GPIO.setup(button_pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
# setup event on pin 10 rising edge
GPIO.add_event_detect(button_pin, GPIO.RISING, callback=button_callback)

message = input("Press enter to quit \n\n") # run until someone presses enter
GPIO.cleanup() # cleanup
