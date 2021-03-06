// pi_two_player.ck
// John Eagle
// 9.25.19
// for canals, Unheard-of//Ensemble

// cello

// osc
OscIn in;
OscMsg msg;
10001 => in.port;
in.listenAll();

// sound network
SinOsc s => dac;

// because of distortion 
dac.gain(0.9); // is this too high?

// initialize volume
0 => s.gain;

// GLOBAL VARIABLES

// timing array
[0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 285, 300, 315, 330, 345, 360, 375, 390, 420, 450, 480, 510, 525, 540, 555, 570, 585, 600, 615, 630, 660, 690, 720, 750, 780, 810, 840, 870] @=> int times[];

// cello freq array                                                                                                                   100.43/218.63/267.57/280.97
[0.0, 154.33, 120.00, 149.50, 221.20, 156.23, 187.47, 241.10, 133.93, 157.80, 146.00, 104.20, 167.13, 119.90, 151.63, 151.77, 176.53, 100.43, 127.07, 145.53, 167.53, 150.47, 171.00, 127.93, 167.47, 150.53, 217.87, 112.60, 151.47, 161.63, 126.70, 193.60, 251.50, 187.80, 144.67, 175.13, 107.83, 0.0] @=> float cello_freqs1[];
// cello secondary
[0.0, 115.67, 120.00, 149.50, 221.20, 156.23, 187.47, 241.10, 133.93, 157.80, 146.00, 104.20, 167.13, 119.90, 151.63, 151.77, 176.53, 218.63, 127.07, 145.53, 167.53, 150.47, 171.00, 127.93, 167.47, 150.53, 217.87, 112.60, 151.47, 161.63, 126.70, 193.60, 251.50, 187.80, 144.67, 175.13, 107.83, 0.0] @=> float cello_freqs2[];
// cello speaker freq array
[0.0, 270.03, 179.67, 277.63, 196.63, 138.83, 421.77, 350.60, 200.63, 262.97, 164.30, 208.20, 100.33, 102.83, 108.33, 202.47, 274.50, 267.57, 190.63, 181.87, 230.30, 200.73, 199.43, 191.93, 125.53, 180.53, 177.03, 100.13, 118.97, 129.30, 168.93, 145.10, 501.97, 225.43, 126.53, 100.00, 258.67, 0.0] @=> float cello_spkr_freqs1[];
// cello speaker secondary
[0.0, 270.03, 179.67, 277.63, 196.63, 138.83, 421.77, 350.60, 200.63, 262.97, 164.30, 208.20, 100.33, 102.83, 108.33, 202.47, 274.50, 280.97, 190.63, 181.87, 230.30, 200.73, 199.43, 191.93, 125.53, 180.53, 177.03, 100.13, 118.97, 129.30, 168.93, 145.10, 501.97, 225.43, 126.53, 100.00, 258.67, 0.0] @=> float cello_spkr_freqs2[];
// cello amplitude array
[0.0,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7, 0.0] @=> float cello_amps[];

// time variables
0 => int second_i; // current second
0 => int displayMinute => int displaySecond; // for display
900 => int end; // when to stop loop

0 => int index; // freq array index
0 => int soundOn; // switch for sound (0 or 1)
15.0 => float thresh; // distance threshold (lower than values trigger sound)

// adjust starting position if command line argument present
Std.atoi(me.arg(0)) => index; // user provides section number (same as index value)
times[index] => second_i; // sets second_i from index
<<< "start at index:", index, "second:", second_i >>>;

// gain variables
0.0 => float targetGain;
0.0 => float gainPosition;
0.005 => float gainInc;

// functions
fun void fadeIn()
{
    while( gainPosition <= targetGain )
    {
        gainPosition + gainInc => gainPosition;
        gainPosition => s.gain;
        //<<< gainPosition >>>;
        10::ms => now;
    }
    //<<< "end" >>>;
}

fun void fadeOut()
{
    while( gainPosition > 0.0 )
    {
        gainPosition - gainInc => gainPosition;
        gainPosition => s.gain;
        10::ms => now;
    }
}

fun void get_reading()
{
    while( second_i <= end )
    { 
        // check for osc messages
        in => now;
        while( in.recv(msg)) {
            // ultrasonic sensor distance
            if( msg.address == "/distance" )
            {
                <<< "/distance", msg.getFloat(0) >>>;
                // turn on sound if value below thresh
                if ( msg.getFloat(0) < thresh && msg.getFloat(0) > 0.0)
                {
                    //<<< "sound on!" >>>;
                    1 => soundOn;
                    cello_spkr_freqs1[index-1] => s.freq;
                    if( cello_spkr_freqs1[index-1] > 350) cello_amps[index-1] * 0.7 => targetGain;
                    else if( cello_spkr_freqs1[index-1] > 250 ) cello_amps[index-1] * 0.8 => targetGain;
                    else if( cello_spkr_freqs1[index-1] > 150 ) cello_amps[index-1] * 0.9 => targetGain;
                    else cello_amps[index-1] * 1.05 => targetGain;
                    //cello_amps[index-1] => targetGain; // index-1?                    
                    spork ~ fadeIn();
                }
                else if ( msg.getFloat(0) < (thresh*2) && msg.getFloat(0) > 0.0)
                {
                    //<<< "sound on!" >>>;
                    1 => soundOn;
                    cello_spkr_freqs2[index-1] => s.freq;
                    if( cello_spkr_freqs2[index-1] > 350) cello_amps[index-1] * 0.7 => targetGain;
                    else if( cello_spkr_freqs2[index-1] > 250 ) cello_amps[index-1] * 0.8 => targetGain;
                    else if( cello_spkr_freqs2[index-1] > 150 ) cello_amps[index-1] * 0.9 => targetGain;
                    else cello_amps[index-1] * 1.05 => targetGain;
                    //cello_amps[index-1] => targetGain; // index-1?                      
                    spork ~ fadeIn();
                }   
                else
                {
                    0 => soundOn;
                    0.0 => targetGain;
                    spork ~ fadeOut();
                }
            }
        }
    }
}


// MAIN PROGRAM

spork ~ get_reading();

// infinite loop
while( second_i <= end )
{
    second_i / 60 => displayMinute;
    second_i % 60 => displaySecond;
    
    // checks for timing interval to update s
    if( times[index] == second_i ) // only gets triggered at each timing interval
    {
        cello_spkr_freqs1[index] => s.freq;
        <<< "Time: ", times[index], "Freq:", cello_spkr_freqs1[index], "Target Gain:", cello_amps[index] >>>;
        if( index < times.cap()-1 )
        {
            index++;
        }
    }
    <<< "Time:", displayMinute, displaySecond, "Index:", index, "Sound on: ", soundOn , cello_spkr_freqs1[index-1] >>>;
    
    
    // now advance time
    second_i++;
    1::second => now;
}