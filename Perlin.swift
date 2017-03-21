import Foundation

var PERLIN_YWRAPB = 4
var PERLIN_YWRAP = 1<<PERLIN_YWRAPB
var PERLIN_ZWRAPB = 8
var PERLIN_ZWRAP = 1<<PERLIN_ZWRAPB
var PERLIN_SIZE = 4095
var SINCOS_PRECISION = 1.0;
var SINCOS_LENGTH = Int(360.00 / SINCOS_PRECISION);
var DEG_TO_RAD = 0.017453292

var perlin_octaves = 4 // default to medium smooth
var perlin_amp_falloff: Float = 0.5 // 50% reduction/octave

var perlin_TWOPI = Int()
var perlin_PI = Int()
var perlin_cosTable = [Float]()
var perlin = [Float]()

var cosLUT = [Float()]

func initTables(){
    cosLUT.removeAll()  // again, for some reason there was one item (0) when I initialised it
    for i in 0..<SINCOS_LENGTH{
        let angle = Float(i)*Float(DEG_TO_RAD)*Float(SINCOS_PRECISION)
        cosLUT.append(Float(cos(angle)))
    }
}

func noise(x: Float, y: Float, z: Float) -> Float {     // remember to assign 0 to y or z, if unused
    var _x = x
    var _y = y
    var _z = z
    
    if(perlin.isEmpty){
        for _ in 0..<PERLIN_SIZE+1{
            let tmp = Float(arc4random_uniform(99999))/99999.00
            perlin.append(tmp) // perlin[i] = perlinRandom.nextFloat(); -> it's a random float 0...1
        }
        
        perlin_cosTable = cosLUT;
        perlin_PI = SINCOS_LENGTH;
        perlin_TWOPI = SINCOS_LENGTH;
        perlin_PI >>= 1;
    }
    
    if (_x<0){ _x = -_x }
    if (_y<0){ _y = -_y }
    if (_z<0){ _z = -_z }
    
    
    var xi = Int(floor(_x))
    var yi = Int(floor(_y))
    var zi = Int(floor(_z))
    
    var xf = _x - Float(xi)
    var yf = _y - Float(yi)
    var zf = _z - Float(zi)
    
    var rxf = Float()
    var ryf = Float()
    
    var r: Float = 0.0
    var ampl: Float = 0.5
    
    var n1 = Float()
    var n2 = Float()
    var n3 = Float()
    
    for _ in 0..<perlin_octaves{
        var of = xi+(yi<<PERLIN_YWRAPB)+(zi<<PERLIN_ZWRAPB);
        rxf = noise_fsc(i: xf)
        ryf = noise_fsc(i: yf)
        
        n1  = perlin[of&PERLIN_SIZE]
        
        n1 += rxf*(perlin[(of+1)&PERLIN_SIZE]-n1)
        n2  = perlin[(of+PERLIN_YWRAP)&PERLIN_SIZE]
        n2 += rxf*(perlin[(of+PERLIN_YWRAP+1)&PERLIN_SIZE]-n2);
        n1 += ryf*(n2-n1);
        
        of += PERLIN_ZWRAP;
        n2  = perlin[of&PERLIN_SIZE];
        n2 += rxf*(perlin[(of+1)&PERLIN_SIZE]-n2);
        n3  = perlin[(of+PERLIN_YWRAP)&PERLIN_SIZE];
        n3 += rxf*(perlin[(of+PERLIN_YWRAP+1)&PERLIN_SIZE]-n3);
        n2 += ryf*(n3-n2);
        n1 += noise_fsc(i: zf) * (n2-n1)
        
        r += n1*ampl
        ampl *= perlin_amp_falloff
        
        xi <<= 1
        xf *= 2
        yi <<= 1
        yf *= 2
        zi <<= 1
        zf *= 2
        
        if (xf >= 1.0){
            xi += 1
            xf -= 1
        }
        if (yf >= 1.0){
            yi += 1
            yf -= 1
        }
        if (zf >= 1.0){
            zi += 1
            zf -= 1
        }
    }
    
    return r
}

func noise_fsc(i: Float) -> Float {
    return 0.5*(1.0-perlin_cosTable[Int((i*Float(perlin_PI)).truncatingRemainder(dividingBy: (Float)(perlin_TWOPI)))]);
}

func noiseDetail(lod: Int, falloff: Float){
    if(lod>0){
        perlin_octaves = lod
    }
    if(falloff>0){
        perlin_amp_falloff = falloff
    }
}
