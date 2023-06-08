global function RegisterScrollbar
global function SetScrollbarSliderHeight

// This only supports vertical scrolling atm
void function RegisterScrollbar( var scrollbar, void functionref( int x, int y ) callback )
{
    var representative = Hud_GetChild( scrollbar, "MouseMovementCapture" )
    AddMouseMovementCaptureHandler( representative, void function( int x, int y ) : ( scrollbar, representative, callback )
    {
        int representativeHeight = Hud_GetY( representative )

        int min = Hud_GetY( scrollbar )
        int max = min + Hud_GetHeight( scrollbar ) - Hud_GetHeight( representative )
        int new = representativeHeight + y
        
        Hud_SetFocused( Hud_GetChild( scrollbar, "SliderButton" ) )

        vector ornull cursor = NSGetCursorPosition()
        if ( cursor == null )
            return
        expect vector( cursor )

        if( new > max ) new = max
        else if( new < min ) new = min

        int movedY = new - Hud_GetY( representative )

        int absY = Hud_GetAbsY( scrollbar ) // doing this in the callback to account for moving scrollbars
        if ( movedY < 0 && cursor.y > absY + max || movedY > 0 && cursor.y < absY ) return // only move the slider if the cursor is in bounds

        SetComponentContentY( scrollbar, new )

        callback( x, movedY ) // call the callback with the pixels the slider has been moved
    } )
}

void function SetScrollbarSliderHeight( var component, int height )
{
    Hud_SetHeight( Hud_GetChild( component, "MouseMovementCapture" ), height )
    Hud_SetHeight( Hud_GetChild( component, "SliderButton" ), height )
    Hud_SetHeight( Hud_GetChild( component, "SliderPanel" ), height )
}

void function SetComponentContentY( var component, int y )
{
    Hud_SetY( Hud_GetChild( component, "MouseMovementCapture" ), y )
    Hud_SetY( Hud_GetChild( component, "SliderButton" ), y )
    Hud_SetY( Hud_GetChild( component, "SliderPanel" ), y )
}
