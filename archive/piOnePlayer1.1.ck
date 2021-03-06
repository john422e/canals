// pi_one_player.ck
// John Eagle
// 9.25.19
// for canals, Unheard-of//Ensemble

// clarinet

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

// clarinet freq array -- don't need this, for reference only
[0.0, 196.37, 239.70, 194.30, 442.50, 334.93, 276.07, 317.97, 187.47, 300.27, 196.90, 332.97, 250.47, 205.57, 198.57, 202.47, 274.50, 267.57, 228.70, 252.20, 230.30, 200.73, 199.43, 184.27, 188.47, 0.0, 202.30, 197.40, 269.30, 271.40, 253.37, 281.67, 267.77, 266.33, 337.20, 300.73, 345.20, 0.0] @=> float clar_freqs[];
// clarinet speaker freq array
[0.0, 147.27, 319.67, 145.73, 353.90, 133.97, 245.37, 275.50, 160.80, 225.40, 123.13, 208.20, 214.60, 128.50, 158.87, 303.90, 190.07, 170.27, 127.07, 236.47, 204.67, 100.17, 133.00, 153.60, 167.47, 0.0, 140.07, 262.97, 151.47, 226.20, 168.93, 140.87, 133.80, 225.43, 126.53, 100.00, 313.93, 0.0] @=> float clar_spkr_freqs[];
// clarinet amplitude array
[0.0,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9, 0.0,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9, 0.0] @=> float clar_amps[];

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
                    clar_spkr_freqs[index-1] => s.freq;
                    if( clar_spkr_freqs[index-1] > 350) clar_amps[index-1] * 0.7 => targetGain;
                    else if( clar_spkr_freqs[index-1] > 250 ) clar_amps[index-1] * 0.8 => targetGain;
                    else if( clar_spkr_freqs[index-1] > 150 ) clar_amps[index-1] * 0.9 => targetGain;
                    else clar_amps[index-1] * 1.05 => targetGain;
                    //clar_amps[index-1] => targetGain; // index-1?
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
        clar_spkr_freqs[index] => s.freq;
        <<< "Time: ", times[index], "Freq:", clar_spkr_freqs[index], "Target Gain:", clar_amps[index] >>>;
        if( index < times.cap()-1 )
        {
            index++;
        }
    }
    <<< "Time:", displayMinute, displaySecond, "Index:", index, "Sound on: ", soundOn , clar_spkr_freqs[index-1] >>>;
    
    
    // now advance time
    second_i++;
    1::second => now;
}