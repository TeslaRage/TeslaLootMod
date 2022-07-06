//----------------------------------------------------------------------------
//  FILE:    UIListItemString_TLM.uc by RustyDios
//
//	Created:	01/07/22	21:00
//	Updated:	02/07/22	10:40
//
//  PURPOSE: Custom Loot Panel item for Tesla Loot Mod
//
//----------------------------------------------------------------------------

class UIListItemString_TLM extends UIPanel;

var UIImage Image;
var UIPanel SplitLine1, SplitLine2;
var UIX2PanelHeader TitleHeader;
var UIBGBox TextBG, BoundingBox;
var UITextContainer TextDescription;

var bool bSizeRealized, bIsRareItem, bIsPsiItem;

var UIList List;	//Parent List we belong too
var string Text, TextTitle, strHexColor;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	INIT AND BUILD LIST ITEM ELEMENTS
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function UIListItemString_TLM InitTLMListItem(optional name InitName,
														optional string InitTitle, 
														optional string InitImage, 
														optional string InitDescription,
														optional string InitHexColor)
{
	local int MyX, MyY, MyW, MyH;

	MyX = 0;  MyY = 0;  MyW = 330;  MyH = 660;
	
	InitPanel(InitName);

	strHexColor = InitHexColor;

	//Outline box to control mouse clicking
	BoundingBox = Spawn(class'UIBGBox', self);
	BoundingBox.bAnimateOnInit = false;
	BoundingBox.InitBG('BoundingBox');
	BoundingBox.SetOutline(true);
	BoundingBox.SetSize(Myw -5, MyH -10);
	BoundingBox.SetColor(class'UIUtilities_Colors'.const.FADED_HTML_COLOR);
	BoundingBox.SetAlpha(33);

	//the item image
	Image = Spawn(class'UIImage', self);
	Image.InitImage('EntryImage1', InitImage);
	Image.SetSize(256, 128); //half the size of the standard image file, needs to be a 2:1 ratio! hardset!
	Image.SetPosition(MyX +((MyW - 256) /2), MyY +5); //37,5

	//setup a 'linebreak'
	SplitLine1 = Spawn(class'UIPanel', self);
	SplitLine1.InitPanel('', class'UIUtilities_Controls'.const.MC_GenericPixel);
	SplitLine1.SetSize( MyW - 27, 2 );
	SplitLine1.SetPosition(MyX +10, MyY +142);

	//setup the text panel title
	TitleHeader = Spawn(class'UIX2PanelHeader', self);
	TitleHeader.bAnimateOnInit = false;
	TitleHeader.InitPanelHeader('EntryTitle', InitTitle, "");
	TitleHeader.SetHeaderWidth(MyW -27);
	TitleHeader.bRealizeOnSetText = true;	//allows recolouring of the title
	TitleHeader.SetPosition(MyX +10, MyY +140);

	//setup a 'linebreak'
	SplitLine2 = Spawn(class'UIPanel', self);
	SplitLine2.InitPanel('', class'UIUtilities_Controls'.const.MC_GenericPixel);
	SplitLine2.SetSize( MyW -27, 2 );
	SplitLine2.SetPosition(MyX +10, MyY +180);

	//setup the text background panel
	TextBG = Spawn(class'UIBGBox', self);
	TextBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	TextBG.InitBG('EntryText_BG',MyX +4, MyY +185, MyW -15, MyH -196); // pos x, pos y , width, height

	//setup the main body description text, size and position
	TextDescription = Spawn(class'UITextContainer', self);
	TextDescription.scrollbarPadding = 8;	//never going to have a scrollbar for this element, so meh
	TextDescription.InitTextContainer();
	TextDescription.bAutoScroll = true;		//set box to autoscroll as the twin scrollbar setup is busted
	TextDescription.SetSize(MyW -27, MyH -220);
	TextDescription.SetPosition(MyX +10, MyY +195);
	TextBG.ProcessMouseEvents(TextDescription.OnChildMouseEvent);

	//perform initiation tasks
	TitleHeader.SetText(InitTitle, "");
	SetText(InitDescription);

	if(strHexColor != "")
	{
		SplitLine1.SetColor( strHexColor );	SplitLine1.SetAlpha( 15 );
		SplitLine2.SetColor( strHexColor );	SplitLine2.SetAlpha( 15 );
	}
	else
	{
		SplitLine1.SetColor( class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR );	SplitLine1.SetAlpha( 15 );
		SplitLine2.SetColor( class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR );	SplitLine2.SetAlpha( 15 );
	}

	//ensure the outline box is above anything else so it looks correct on highlight
	BoundingBox.MoveToHighestDepth();
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	SET NEW DATA
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

//intentionally does not call the super function, we should never need to call this
simulated function SetWidth(float NewWidth)
{
	Width = NewWidth;
}

//change displayed image
simulated function UIListItemString_TLM SetImage(string ImagePath)
{
	if (ImagePath != Image.ImagePath)
	{
		Image.ImagePath = ImagePath;
		Image.LoadImage(ImagePath);
	}

	return self;
}

//change title text, also set item as 'complete'
simulated function UIListItemString_TLM SetTitle(string Title)
{
	if (TextTitle != Title)
	{
		TextTitle = Title;
		TitleHeader.SetText(Title, "");
	}

	bSizeRealized = true;
	return self;
}

//change body description text, auto centers based on description box size
simulated function UIListItemString_TLM SetText(string NewText)
{
	if(Text != NewText)
	{
		Text = NewText;
        TextDescription.SetHtmlText(class'UIUtilities_Text'.static.AlignCenter(NewText));
	    TextDescription.Text.SetHeight(TextDescription.Text.Height * 8.0f);
	}

	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	BOUNDING BOX MANIPULATION FOR HIGHLIGHTS
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	BoundingBox.SetColor(class'UIUtilities_Colors'.const.GOOD_HTML_COLOR);

	if(bIsRareItem)
	{
		BoundingBox.SetColor(class'UIUtilities_Colors'.const.WARNING2_HTML_COLOR);
	}

	if(bIsPsiItem)
	{
		BoundingBox.SetColor(class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR);
		BoundingBox.SetAlpha(66);
	}

	if(strHexColor != "")
	{
		BoundingBox.SetColor(strHexColor);
	}
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	BoundingBox.SetColor(class'UIUtilities_Colors'.const.FADED_HTML_COLOR);
	BoundingBox.SetAlpha(22);
}

//custom colour overide for rare items
simulated function UIListItemString_TLM SetAsRareItem()
{
	SplitLine1.SetColor( class'UIUtilities_Colors'.const.WARNING2_HTML_COLOR );	SplitLine1.SetAlpha( 33 );
	SplitLine2.SetColor( class'UIUtilities_Colors'.const.WARNING2_HTML_COLOR );	SplitLine2.SetAlpha( 33 );

	bIsRareItem = true;

	return self;
}

//custom colour overide for psi items
simulated function UIListItemString_TLM SetAsPsiItem()
{
	SplitLine1.SetColor( class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR );	SplitLine1.SetAlpha( 33 );
	SplitLine2.SetColor( class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR );	SplitLine2.SetAlpha( 33 );

	bIsPsiItem = true;

	return self;
}

//custom colour overide for other items
simulated function UIListItemString_TLM SetCustomColor(string HexColor, int iAlpha)
{
	SplitLine1.SetColor( HexColor );	SplitLine1.SetAlpha( iAlpha );
	SplitLine2.SetColor( HexColor );	SplitLine2.SetAlpha( iAlpha );

	strHexColor = HexColor;

	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	DEFAULT PROPERTIES
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	bAnimateOnInit = false;

	bCascadeFocus = false;

	width = 340;
	height = 680;

	//ALLOW THIS ELEMENT TO PROCCESS THE MOUSE
	bProcessesMouseEvents = true;
}
