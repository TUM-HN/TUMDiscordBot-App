import SwiftUI

// Official TUM Color Palette
extension Color {
    // Main colors
    static let tumBlue = Color(red: 48/255, green: 112/255, blue: 179/255)       // TUM blue brand #3070B3
    static let tumBlueDark = Color(red: 7/255, green: 33/255, blue: 64/255)      // TUM blue dark #072140
    static let tumOrange = Color(red: 247/255, green: 129/255, blue: 30/255)     // TUM orange #F7811E
    static let tumYellow = Color(red: 254/255, green: 215/255, blue: 2/255)      // TUM yellow #FED702
    static let tumPink = Color(red: 181/255, green: 92/255, blue: 165/255)       // TUM pink #B55CA5
    
    // Blue variations
    static let tumBlueDark1 = Color(red: 10/255, green: 45/255, blue: 87/255)    // TUM blue dark 1 #0A2D57
    static let tumBlueDark2 = Color(red: 14/255, green: 57/255, blue: 110/255)   // TUM blue dark 2 #0E396E
    static let tumBlueDark3 = Color(red: 17/255, green: 69/255, blue: 132/255)   // TUM blue dark 3 #114584
    static let tumBlueDark4 = Color(red: 20/255, green: 81/255, blue: 154/255)   // TUM blue dark 4 #14519A
    static let tumBlueDark5 = Color(red: 22/255, green: 93/255, blue: 177/255)   // TUM blue dark 5 #165DB1
    
    static let tumBlueLight = Color(red: 94/255, green: 148/255, blue: 212/255)  // TUM blue light #5E94D4
    static let tumBlueLightDark = Color(red: 154/255, green: 188/255, blue: 228/255) // TUM blue light dark #9ABCE4
    static let tumBlueLight2 = Color(red: 194/255, green: 215/255, blue: 239/255) // TUM blue light 2 #C2D7EF
    static let tumBlueLight3 = Color(red: 215/255, green: 228/255, blue: 244/255) // TUM blue light 3 #D7E4F4
    static let tumBlueLight4 = Color(red: 227/255, green: 238/255, blue: 250/255) // TUM blue light 4 #E3EEFA
    static let tumBlueLight5 = Color(red: 240/255, green: 245/255, blue: 250/255) // TUM blue light 5 #F0F5FA
    
    // Yellow variations
    static let tumYellowDark = Color(red: 203/255, green: 171/255, blue: 1/255)   // TUM yellow dark #CBAB01
    static let tumYellow1 = Color(red: 254/255, green: 222/255, blue: 52/255)     // TUM yellow 1 #FEDE34
    static let tumYellow2 = Color(red: 254/255, green: 230/255, blue: 103/255)    // TUM yellow 2 #FEE667
    static let tumYellow3 = Color(red: 254/255, green: 238/255, blue: 154/255)    // TUM yellow 3 #FEEE9A
    static let tumYellow4 = Color(red: 254/255, green: 246/255, blue: 205/255)    // TUM yellow 4 #FEF6CD
    
    // Orange variations
    static let tumOrangeDark = Color(red: 217/255, green: 146/255, blue: 8/255)   // TUM orange dark #D99208
    static let tumOrange1 = Color(red: 249/255, green: 191/255, blue: 78/255)     // TUM orange 1 #F9BF4E
    static let tumOrange2 = Color(red: 250/255, green: 208/255, blue: 128/255)    // TUM orange 2 #FAD080
    static let tumOrange3 = Color(red: 252/255, green: 226/255, blue: 176/255)    // TUM orange 3 #FCE2B0
    static let tumOrange4 = Color(red: 254/255, green: 244/255, blue: 225/255)    // TUM orange 4 #FEF4E1
    
    // Pink variations
    static let tumPinkDark = Color(red: 155/255, green: 70/255, blue: 141/255)    // TUM pink dark #9B468D
    static let tumPink1 = Color(red: 198/255, green: 128/255, blue: 187/255)      // TUM pink 1 #C680BB
    static let tumPink2 = Color(red: 214/255, green: 164/255, blue: 206/255)      // TUM pink 2 #D6A4CE
    
    // For backward compatibility with existing code
    static let tumGreen = Color(red: 159/255, green: 186/255, blue: 54/255)      // Using #9FBA36
    static let tumRed = Color(red: 234/255, green: 114/255, blue: 55/255)        // Using #EA7237
    static let tumBlueBright = Color(red: 143/255, green: 129/255, blue: 234/255) // Using #8F81EA
    
    // Gray shades (keeping these for compatibility)
    static let tumGray1 = Color(red: 32/255, green: 37/255, blue: 42/255)        // Dark gray #20252A
    static let tumGray2 = Color(red: 51/255, green: 58/255, blue: 65/255)        // Mid dark gray #333A41
    static let tumGray3 = Color(red: 71/255, green: 80/255, blue: 88/255)        // Mid gray #475058
    static let tumGray4 = Color(red: 106/255, green: 117/255, blue: 126/255)     // Light mid gray #6A757E
    static let tumGray7 = Color(red: 221/255, green: 226/255, blue: 230/255)     // Light gray #DDE2E6
    static let tumGray8 = Color(red: 235/255, green: 236/255, blue: 239/255)     // Very light gray #EBECEF
    static let tumGray9 = Color(red: 251/255, green: 249/255, blue: 250/255)     // Almost white #FBF9FA
} 
