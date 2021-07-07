// pi_two_player.ck
// John Eagle
// 9.25.19
// for canals, Unheard-of//Ensemble

// violin

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

// violin freq array      
[0.0, 270.03, 358.63, 259.07, 353.90, 364.53, 337.40, 250.43, 200.63, 354.03, 218.87, 249.97, 313.33, 0.0, 238.17, 303.90, 412.07, 280.97, 272.43, 270.23, 263.13, 300.57, 266.07, 211.10, 251.30, 331.13, 303.47, 225.50, 303.17, 226.20, 253.37, 257.80, 501.97, 488.37, 241.03, 375.17, 221.93, 0.0] @=> float vln_freqs1[];
// violin secondary
[0.0, 270.03, 358.63, 259.07, 353.90, 364.53, 337.40, 250.43, 200.63, 337.6, 218.87, 249.97, 313.33, 0.0, 238.17, 303.90, 412.07, 280.97, 272.43, 270.23, 263.13, 300.57, 266.07, 211.10, 251.30, 331.13, 303.47, 225.50, 303.17, 226.20, 253.37, 257.80, 501.97, 488.37, 241.03, 375.17, 221.93, 0.0] @=> float vln_freqs2[];
// violin speaker freq array
[0.0, 154.33, 179.67, 145.73, 196.63, 130.27, 168.57, 172.20, 100.47, 157.97, 164.30, 208.20, 125.17, 0.0, 173.23, 216.93, 274.50, 140.37, 190.63, 202.80, 230.30, 150.47, 133.00, 153.60, 125.53, 165.53, 252.87, 197.40, 265.17, 113.03, 168.93, 223.43, 143.50, 195.30, 144.67, 214.40, 197.43, 0.0] @=> float vln_spkr_freqs1[];
// violin speaker secondary
[0.0, 154.33, 179.67, 145.73, 196.63, 130.27, 168.57, 172.20, 100.47, 169.03, 164.30, 208.20, 125.17, 0.0, 173.23, 216.93, 274.50, 140.37, 190.63, 202.80, 230.30, 150.47, 133.00, 153.60, 125.53, 165.53, 252.87, 197.40, 265.17, 113.03, 168.93, 223.43, 143.50, 195.30, 144.67, 214.40, 197.43, 0.0] @=> float vln_spkr_freqs2[];
// violin amplitude array
[0.0,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7, 0.0,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7,    0.7, 0.0] @=> float vln_amps[];

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
                    vln_spkr_freqs1[index-1] => s.freq;
                    if( vln_spkr_freqs1[index-1] > 350) vln_amps[index-1] * 0.7 => targetGain;
                    else if( vln_spkr_freqs1[index-1] > 250 ) vln_amps[index-1] * 0.8 => targetGain;
                    else if( vln_spkr_freqs1[index-1] > 150 ) vln_amps[index-1] * 0.9 => targetGain;
                    else vln_amps[index-1] * 1.05 => targetGain;
                    //vln_amps[index-1] => targetGain; // index-1?
                    spork ~ fadeIn();
                }
                else if ( msg.getFloat(0) < (thresh*2) && msg.getFloat(0) > 0.0)
                {
                    //<<< "sound on!" >>>;
                    1 => soundOn;
                    vln_spkr_freqs2[index-1] => s.freq;
                    if( vln_spkr_freqs2[index-1] > 350) vln_amps[index-1] * 0.7 => targetGain;
                    else if( vln_spkr_freqs2[index-1] > 250 ) vln_amps[index-1] * 0.8 => targetGain;
                    else if( vln_spkr_freqs2[index-1] > 150 ) vln_amps[index-1] * 0.9 => targetGain;
                    else vln_amps[index-1] * 1.05 => targetGain;
                    //vln_amps[index-1] => targetGain; // index-1?
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
        vln_spkr_freqs1[index] => s.freq;
        <<< "Time: ", times[index], "Freq:", vln_spkr_freqs1[index], "Target Gain:", vln_amps[index] >>>;
        if( index < times.cap()-1 )
        {
            index++;
        }
    }
    <<< "Time:", displayMinute, displaySecond, "Index:", index, "Sound on: ", soundOn , vln_spkr_freqs1[index-1] >>>;
    
    
    // now advance time
    second_i++;
    1::second => now;
}