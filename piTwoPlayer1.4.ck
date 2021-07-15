// pi_two_player.ck
// John Eagle
// 9.25.19
// for canals, Unheard-of//Ensemble
// updated 7.8.21 for Brightwork recording

// piTwo, violin

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

// violin freq array      
[0.0, 270.03, 358.63, 259.07, 353.90, 364.53, 337.40, 250.43, 200.63, 354.03, 218.87, 249.97, 313.33, 0.0, 238.17, 303.90, 412.07, 280.97, 272.43, 270.23, 263.13, 300.57, 266.07, 211.10, 251.30, 331.13, 303.47, 225.50, 303.17, 226.20, 253.37, 257.80, 501.97, 488.37, 241.03, 375.17, 221.93, 0.0] @=> float vln_freqs1[];
// violin secondary
[0.0, 270.03, 358.63, 259.07, 353.90, 364.53, 337.40, 250.43, 200.63, 337.6, 218.87, 249.97, 313.33, 0.0, 238.17, 303.90, 412.07, 280.97, 272.43, 270.23, 263.13, 300.57, 266.07, 211.10, 251.30, 331.13, 303.47, 225.50, 303.17, 226.20, 253.37, 257.80, 501.97, 488.37, 241.03, 375.17, 221.93, 0.0] @=> float vln_freqs2[];
// violin speaker freq array
[100.0, 154.33, 179.67, 145.73, 196.63, 130.27, 168.57, 172.20, 100.47, 157.97, 164.30, 208.20, 125.17, 0.0, 173.23, 216.93, 274.50, 140.37, 190.63, 202.80, 230.30, 150.47, 133.00, 153.60, 125.53, 165.53, 252.87, 197.40, 265.17, 113.03, 168.93, 223.43, 143.50, 195.30, 144.67, 214.40, 197.43, 0.0] @=> float vln_spkr_freqs1[];
// violin speaker secondary
[200.0, 154.33, 179.67, 145.73, 196.63, 130.27, 168.57, 172.20, 100.47, 169.03, 164.30, 208.20, 125.17, 0.0, 173.23, 216.93, 274.50, 140.37, 190.63, 202.80, 230.30, 150.47, 133.00, 153.60, 125.53, 165.53, 252.87, 197.40, 265.17, 113.03, 168.93, 223.43, 143.50, 195.30, 144.67, 214.40, 197.43, 0.0] @=> float vln_spkr_freqs2[];
// violin amplitude array
//[0.0,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7, 0.0,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7, 0.0] @=> float vln_amps[];

// time variables
0 => int second_i; // current second
0 => int displayMinute => int displaySecond; // for display
900 => int end; // when to stop loop

0 => int index; // freq array index
0 => int soundOn; // switch for sound (0 or 1)
20.0 => float thresh; // distance threshold (lower than values trigger sound)
40.0 => float thresh2;
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
                    vln_spkr_freqs1[index-1] => s.freq;
                    normalize(dist, thresh, distOffset) => amp;
                    //(1 / ( (dist-distOffset) / 2 )) => amp; // testing
                    //Std.fabs(amp) => amp;
                    //if( amp > 1.0 ) 1.0 => amp;
                    <<< amp >>>;
                    amp => e.target;
                    spork ~ e.keyOn();
                }
                // else if further away get secondary tone
                else if ( dist < thresh2 && dist > thresh)
                { // only evaluate if freqs are not the same
                    if ( vln_spkr_freqs1[index-1] != vln_spkr_freqs2[index-1] ) 
                    {
                        //<<< "sound on!" >>>;
                        1 => soundOn;
                        vln_spkr_freqs2[index-1] => s.freq;
                        normalize(dist, thresh, thresh2) => amp;
                        //( (1/dist) - (1/thresh) ) / ( (1/thresh2) - (1/thresh) ) => amp; // testing
                        //Std.fabs(amp) => amp;
                        //if( amp > 1.0 ) 1.0 => amp;
                        <<< amp >>>;
                        amp => e.target;
                        spork ~ e.keyOn();
                    }
                }
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
        vln_spkr_freqs1[index] => s.freq;
        <<< "Time: ", times[index], "Freq:", vln_spkr_freqs1[index], vln_spkr_freqs2[index] >>>;
        if( index < times.cap()-1 )
        {
            index++;
        }
    }
    //<<< "Time:", displayMinute, displaySecond, "Index:", index, "Sound on: ", soundOn , vln_spkr_freqs1[index-1] >>>;
    
    
    // now advance time
    second_i++;
    1::second => now;
}
