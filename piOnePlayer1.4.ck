// pi_one_player.ck
// John Eagle
// 9.25.19
// for canals, Unheard-of//Ensemble
// updated 7.8.21 for Brightwork recording

// piOne, clarinet

0 => int laptop; // NOT IMPLEMENTED YET: if 1, then sensor won't control amp. all tones will play all the time


// osc
OscIn in;
OscMsg msg;
10001 => in.port;
in.listenAll();

// sound network
SinOsc s => Envelope e => LPF f => dac;

// because of distortion 
//dac.gain(0.9); // is this too high?

// setup filters
500 => f.freq;
0.4 => f.Q;

// initialize volume
0 => s.gain;

// startup sound
5 => int countDown;

0.2 => s.gain;
for( 0 => int i; i < countDown; i++ ) {
    220 => s.freq;
    e.keyOn();
    0.5::second => now;
    e.keyOff();
    0.5::second => now;
}
1.0 => s.gain;

// initialize envelope ramp time
0.5 => e.time;

// GLOBAL VARIABLES

// timing array
[0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 285, 300, 315, 330, 345, 360, 375, 390, 420, 450, 480, 510, 525, 540, 555, 570, 585, 600, 615, 630, 660, 690, 720, 750, 780, 810, 840, 870] @=> int times[];

// clarinet freq array -- don't need this, for reference only
[0.0, 196.37, 239.70, 194.30, 442.50, 334.93, 276.07, 317.97, 187.47, 300.27, 196.90, 332.97, 250.47, 205.57, 198.57, 202.47, 274.50, 267.57, 228.70, 252.20, 230.30, 200.73, 199.43, 184.27, 188.47, 0.0, 202.30, 197.40, 269.30, 271.40, 253.37, 281.67, 267.77, 266.33, 337.20, 300.73, 345.20, 0.0] @=> float clar_freqs[];
// clarinet speaker freq array
[0.0, 147.27, 319.67, 145.73, 353.90, 133.97, 245.37, 275.50, 160.80, 225.40, 123.13, 208.20, 214.60, 128.50, 158.87, 303.90, 190.07, 170.27, 127.07, 236.47, 204.67, 100.17, 133.00, 153.60, 167.47, 0.0, 140.07, 262.97, 151.47, 226.20, 168.93, 140.87, 133.80, 225.43, 126.53, 100.00, 313.93, 0.0] @=> float clar_spkr_freqs[];
// clarinet amplitude array
//[0.0,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9, 0.0,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9,    0.9, 0.0] @=> float clar_amps[];





// time variables
0 => int second_i; // current second
0 => int displayMinute => int displaySecond; // for display
900 => int end; // when to stop loop

0 => int index; // freq array index
0 => int soundOn; // switch for sound (0 or 1)
25.0 => float thresh; // distance threshold (lower than values trigger sound)
//30.0 => float thresh2; not used for piOne
5.0 => float distOffset;
float dist;
float amp;

// adjust starting position if command line argument present
Std.atoi(me.arg(0)) => index; // user provides section number (same as index value)
times[index] => second_i; // sets second_i from index
<<< "start at index:", index, "second:", second_i >>>;

// functions

fun float normalize( float inVal, float x1, float x2) {
    /*
    for standard mapping:
    x1 = min, x2 = max
    inverted mapping:
    x2 = min, x1 = max
    */
    // catch out-of-range numbers and cap
    if( x1 > x2 ) { // for inverted ranges
        if( inVal < x2 ) x2 => inVal;
        if( inVal > x1 ) x1 => inVal;
    }
    // normal mapping
    else {
        if( inVal < x1 ) x1 => inVal;
        if( inVal > x2 ) x2 => inVal;
    }
    (inVal-x1) / (x2-x1) => float outVal;
    return outVal;
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
		msg.getFloat(0) => dist;
                //<<< "/distance", dist >>>;
                // turn on sound if value below thresh and get primary tone
                if ( dist < thresh && dist > 0.0)
                {
                    //<<< "sound on!" >>>;
                    1 => soundOn;
                    clar_spkr_freqs[index-1] => s.freq;
                    normalize(dist, thresh, distOffset) => amp;
                    //(1 / ( (dist-distOffset) / 2 )) => amp; // testing
                    //Std.fabs(amp) => amp;
                    //if( amp > 1.0 ) 1.0 => amp;
                    <<< amp >>>;
                    amp => e.target;
                    spork ~ e.keyOn();
                }
                // else if further away get secondary tone // NOT USED FOR piONE
                
                
                
                
                
                
                
                
                
                
             
             
             
                
                
                else // no sound
                {
                    0 => soundOn;
                    spork ~ e.keyOff();
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
        <<< "Time: ", times[index], "Freq:", clar_spkr_freqs[index] >>>;
        if( index < times.cap()-1 )
        {
            index++;
        }
    }
    //<<< "Time:", displayMinute, displaySecond, "Index:", index, "Sound on: ", soundOn , clar_spkr_freqs[index-1] >>>;
    
    
    // now advance time
    second_i++;
    1::second => now;
}
