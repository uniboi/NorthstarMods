global function AddNorthstarQuickplayMenu

struct {
    var menu
    var launchQPButton
    array<ServerInfo> servers

    struct {
        var view
        array<var> panels
        var scrollbar
        var slider

        int scrollOffset
        array<string> filteredModes
    } modesView

    struct {
        var view
        array<var> panels
        var scrollbar
        var slider

        int scrollOffset
        array<string> filteredMaps
    } mapsView
} file

const MODE_PANELS = 4
const MAP_PANELS = 6
const MAP_COLUMNS = 2
const MAP_ROWS = MAP_PANELS / MAP_COLUMNS

//////////////////////////////
// Setup
//////////////////////////////

void function AddNorthstarQuickplayMenu()
{
    AddMenu( "QuickplayMenu", $"resource/ui/menus/quickplay.menu", QuickplayMenu_Init)
}

void function QuickplayMenu_Init()
{
    file.menu = GetMenu( "QuickplayMenu" )
    file.launchQPButton = Hud_GetChild( file.menu, "BtnPlay" )
    
    thread UpdateServers()

    // RuiSetImage( Hud_GetRui( file.launchQPButton ), "buttonImage", $"rui/menu/common/gender_button_male" )
    SetButtonRuiText( file.launchQPButton, "#QUICKPLAY_START" )
    Hud_SetText( file.launchQPButton, "Test" )
    AddButtonEventHandler( file.launchQPButton, UIE_CLICK, OnQuickplayButtonPressed )

    AddMenuEventHandler( file.menu, eUIEvent.MENU_OPEN, OnQuickplayMenuOpened )
    AddMenuFooterOption( file.menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )
    
    // === Mode list ===
    file.modesView.view = Hud_GetChild( file.menu, "ModeSelectView" )
    file.modesView.panels = GetElementsByClassname( file.menu, "ModePanel" )
    file.modesView.scrollbar = Hud_GetChild( file.modesView.view, "ModeScrollbar" )
    file.modesView.slider = Hud_GetChild( file.modesView.scrollbar, "MouseMovementCapture" )

    RegisterScrollbar( file.modesView.scrollbar, OnModeListScrollbarMoved )

    // === Map list ===
    file.mapsView.view = Hud_GetChild( file.menu, "MapSelectView" )
    file.mapsView.panels = GetElementsByClassname( file.menu, "MapPanel" )
    file.mapsView.scrollbar = Hud_GetChild( file.mapsView.view, "MapScrollbar" )
    file.mapsView.slider = Hud_GetChild( file.mapsView.scrollbar, "MouseMovementCapture" )

    Hud_SetHeight( file.mapsView.scrollbar, Hud_GetHeight( file.mapsView.panels[ 0 ] ) * MAP_ROWS )
    RegisterScrollbar( file.mapsView.scrollbar, OnMapListScrollbarMoved )

    file.mapsView.filteredMaps = GetPrivateMatchMaps() // Set this to vanilla maps initially. Will be overridden when opening the menu to include custom maps

    // Initialize the first map panels. This can be done at init because vanilla map order will always be the same
    for ( int i; i < MAP_PANELS; i++ )
    {
        UpdateMapPanel( file.mapsView.panels[ i ], file.mapsView.filteredMaps[ i ] )
    }
}

//////////////////////////////
// Menu logic
//////////////////////////////

void function OnQuickplayMenuOpened()
{
    UI_SetPresentationType( ePresentationType.KNOWLEDGEBASE_MAIN )

    InitModesList()
    InitMapsList()
}

void function InitMapsList()
{
    // Set up all possible maps
    // This can't be done at init because mods can add new maps
    file.mapsView.filteredMaps = GetPrivateMatchMaps()

    // Update the map list slider height according to maps to display initially
    SetScrollbarSliderHeight( file.mapsView.scrollbar, Hud_GetHeight( file.mapsView.scrollbar ) / ( ( file.mapsView.filteredMaps.len() - MAP_ROWS ) / MAP_COLUMNS ) )
}

void function InitModesList()
{
    file.modesView.filteredModes = GetPrivateMatchModes()
    SetScrollbarSliderHeight( file.modesView.scrollbar, Hud_GetHeight( file.modesView.scrollbar ) / ( file.modesView.filteredModes.len() - MODE_PANELS ) )

    // TODO: State should be preserved when reopening
    for ( int i; i < MODE_PANELS; i++ )
    {
        UpdateModePanel( file.modesView.panels[ i ], file.modesView.filteredModes[ i ] )
    }
}

//////////////////////////////
// Scrollbars
//////////////////////////////

// === Modes ===

void function OnModeListScrollbarMoved( int x, int y )
{
    file.modesView.scrollOffset = Hud_GetY( file.modesView.slider ) / Hud_GetHeight( file.modesView.slider )

    foreach( int i, var panel in file.modesView.panels )
    {
        UpdateModePanel( panel, file.modesView.filteredModes[ i + file.modesView.scrollOffset ] )
    }
}

void function UpdateModePanel( var panel, string mode )
{
    // TODO: move to different .res
    RuiSetImage( Hud_GetRui( Hud_GetChild( panel, "MapImage" ) ), "basicImage", GetPlaylistImage( mode ) )
    Hud_SetText( Hud_GetChild( panel, "MapName" ), GetGameModeDisplayName( mode ) )
}

// === Maps ===

void function OnMapListScrollbarMoved( int x, int y )
{
    int originalScrollOffset = file.mapsView.scrollOffset
    file.mapsView.scrollOffset = ( Hud_GetY( file.mapsView.slider ) / Hud_GetHeight( file.mapsView.slider ) ) * MAP_COLUMNS

    if ( originalScrollOffset == file.mapsView.scrollOffset )
    {
        return // Don't render anything because nothing has changed
    }

    for ( int rowIdx; rowIdx < MAP_ROWS; rowIdx++ )
    {
        for ( int colIdx; colIdx < MAP_COLUMNS; colIdx++ )
        {
            int idx = rowIdx * MAP_COLUMNS + colIdx
            var panel = file.mapsView.panels[ idx ]
            int contentIndex = file.mapsView.scrollOffset + idx

            if ( contentIndex >= file.mapsView.filteredMaps.len() )
            {
                Hud_Hide( panel )
            }
            else
            {
                Hud_Show( panel )
                UpdateMapPanel( panel, file.mapsView.filteredMaps[ contentIndex ] )
            }

        }
    }
}

void function UpdateMapPanel( var panel, string map )
{
    RuiSetImage( Hud_GetRui( Hud_GetChild( panel, "MapImage" ) ), "basicImage", GetMapImageForMapName( map ) )
    Hud_SetText( Hud_GetChild( panel, "MapName"), GetMapDisplayName( map ) )
}

//////////////////////////////
// Quickplay Logic
//////////////////////////////

void function OnQuickplayButtonPressed( var button )
{

}

// Fetch all servers and update UI elements depending on them
void function UpdateServers()
{
    NSClearRecievedServerList() // This might fuck you over if you switch to the serverbrowser fast enough
    NSRequestServerList()

    // There's no async mechanism for this yet
    while ( NSIsRequestingServerList() )
    {
        WaitFrame()
    }

    file.servers = NSGetGameServers()
}
