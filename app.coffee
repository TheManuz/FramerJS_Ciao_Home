do -> Array::shuffle ?= ->
	for i in [@length-1..1]
		j = Math.floor Math.random() * (i + 1)
		[@[i], @[j]] = [@[j], @[i]]
	@

# This imports all the layers for "Ciao_home" into sketchat_home2Layers
layers = Framer.Importer.load "imported/Ciao_home"
Framer.Device.contentScale = 2
#Framer.Device.background.image = "image.jpg"
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
#DEFAULTS VALUES
GRIDSIZE = 3
NUMBEROFCONTACTS = 1
MASCOTTE_NAME = "Echo"
MARGIN = 1

CUSTOMDRAWINGS = []
CUSTOMDRAWINGS.push window.welcomeDrawing1
CUSTOMDRAWINGS.push window.welcomeDrawing2
CUSTOMDRAWINGS.push window.welcomeDrawing3
CONTACTS = window.contactList
CONTACTS = Utils.cycle(CONTACTS.contacts.shuffle())
# CONTACTS_COLORS = Utils.cycle(["#ffc400", "#14e715", "#4d73ff", "#f50057"]) #A400
# CONTACTS_COLORS = Utils.cycle(["#ffca28", "#9ccc65", "#26c6da", "#5c6bc0", "#ec407a", "#ffa726"]) #400 rainbow
# CONTACTS_COLORS = Utils.cycle(["#9ccc65", "#ffca28", "#5c6bc0", "#26c6da", "#ff7043", "#ec407a"]) #400 scrambled
CONTACTS_COLORS = ["#ffa726", "#5c6bc0", "#26c6da", "#ff7043", "#9ccc65", "#ec407a"] #400 removed yellow, replaced with orange
# COLORS = Utils.domLoadJSONSync "./colors.json"
SHORTANIMTIME = 0.2
LONGANIMTIME = 0.6
PLAYDURATION = 2
AVATARFREQUENCY = 0
AVATARSIZE = 105 #131 #Math.round((320 - MARGIN*(GRIDSIZE+1)) / GRIDSIZE)
DRAWAVATARSIZE = Math.round((320 - MARGIN*(3+1)) / 3)
SENDPOSITION = 320-MARGIN-DRAWAVATARSIZE
SHEETSIZE = 320-32
LABELWIDTH = 320-DRAWAVATARSIZE-MARGIN*3
LABELHEIGHT = 48
STROKEWIDTH = 14

LABELSTYLE =
	fontFamily: "Roboto", lineHeight: '48px',
	textAlign: "left", verticalAlign: "middle"
	fontSize: "16px", fontStyle: "normal",
	fontWeight: 400, color: '#fff',
	padding: "0 8px"

materialCurveMove = "cubic-bezier(0.4, 0, 0.2, 1)"
materialCurveEnter = "cubic-bezier(0, 0, 0.2, 1)"
materialCurveExit = "cubic-bezier(0.4, 0, 1, 1)"

#DRAWING OPTIMIZER
# drawingToOptimize = CUSTOMDRAWINGS[2]
# console.log drawingToOptimize.x.length
# i = 0
# while i < drawingToOptimize.x.length
# 	if drawingToOptimize.n[i] is false and (i-drawingToOptimize.x.length)%4 isnt 0
# 		console.log i
# 		drawingToOptimize.x.splice(i, 1)
# 		drawingToOptimize.y.splice(i, 1)
# 		drawingToOptimize.n.splice(i, 1)
# 		i--
# 	i++
# console.log drawingToOptimize.x.length
# console.log '"x" : ['+drawingToOptimize.x+'],\n\t"y" : ['+drawingToOptimize.y+'],\n\t"n" : ['+drawingToOptimize.n+']'

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
Framer.Defaults.Animation =
	curve: materialCurveMove
	time: LONGANIMTIME
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
#INITIALIZE STATES FOR PSD LAYERS
for b in [
	"back_button", "new_button", "reply_button", "undo_button"
	"replay_icon", "next_icon", "new_icon"
	"paging_new", "paging_replay"]
	layers[b].states.add
		hidden: {scale:0, opacity:0}
	layers[b].states.switchInstant "hidden"

layers["replay_icon"].states.add selected: {scale:2, opacity:0}, hidden: {scale:0, opacity:0}
layers["next_icon"].states.add selected: {scale:2, opacity:0}, hidden: {scale:0, opacity:0}
layers["new_icon"].states.add selected: {scale:2, opacity:0}, hidden: {scale:0, opacity:0}

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
#MAIN LAYERS
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
mainScreen = new Layer
	x: 0, y: 0, width: 320, height: 568
	backgroundColor: "#fff"
	
contactsScroll = new Layer
	superLayer: mainScreen
	x: 0, y: 64, width: 320, height: 0, clip: false
	backgroundColor: "transparent"

layers["settings_bar"].superLayer = mainScreen
layers["settings_bar"].states.add
	minimized: {height: 20}
layers["settings_label"].states.add
	hidden: {y: 28-44, opacity: 0}
layers["settings_icon"].states.add
	hidden: {y: 30-44, opacity: 0}

drawScreen = new Layer
	superLayer: mainScreen
	x: 0, y: 0, width: 320, height: 568
	backgroundColor: "transparent"

contactsScroll.dragSnap = (event) ->
	snapfactor = AVATARSIZE+MARGIN
	velocity = this.draggable.calculateVelocity()
	clampedVelocity = Math.max(-snapfactor, Math.min(velocity.y*100, snapfactor))
	targetY = Math.round((this.y+clampedVelocity)/snapfactor) * snapfactor
	targetY = Math.min(layers["settings_bar"].targetHeight, Math.max(targetY, -contactsScroll.contentFrame().height + 568 - MARGIN))
	snapAnim = this.animate
		properties:
			y: targetY
			
contactsScroll.sortAvatars = () ->
	for avatar in contactsScroll.subLayers
		avatar.y = (AVATARSIZE+MARGIN) * avatar.position
		
contactsScroll.bubbleAvatarUp = (index) ->
	for avatar in contactsScroll.subLayers
		if avatar.position < index
			avatar.position++
		else if avatar.position is index
			avatar.position = 0
	contactsScroll.sortAvatars()
	
contactsScroll.getAvatarByPosition = (index) ->
	for avatar in contactsScroll.subLayers
		if avatar.position is index
			return avatar

contactsScroll.on Events.DragMove, () ->
	layers["settings_bar"].height = Utils.modulate(this.y, [20, 64], [20, 64], true)
	layers["settings_label"].y = Utils.modulate(this.y, [20, 64], [28-44, 28], true)
	layers["settings_label"].opacity = Utils.modulate(this.y, [20, 64], [0, 1], true)
	layers["settings_icon"].y = Utils.modulate(this.y, [20, 64], [30-44, 30], true)
	layers["settings_icon"].opacity = Utils.modulate(this.y, [20, 64], [0, 1], true)
	#DISABLE ALL CONTACTS
	velocity = @draggable.calculateVelocity()
	if Math.abs(velocity.y) > 0.1
		for avatar in contactsScroll.subLayers
			avatar.draggable.enabled = false
	
contactsScroll.on Events.DragEnd, () ->
	if layers["settings_bar"].height > (20+64)*0.5
		layers["settings_bar"].targetHeight = 64
		layers["settings_bar"].states.switch "default"
		layers["settings_label"].states.switch "default"
		layers["settings_icon"].states.switch "default"
	else
		layers["settings_bar"].targetHeight = 20
		layers["settings_bar"].states.switch "minimized"
		layers["settings_label"].states.switch "hidden"
		layers["settings_icon"].states.switch "hidden"
	contactsScroll.dragSnap()
	#RE-ENABLE ALL CONTACTS
	for avatar in this.subLayers
		avatar.draggable.enabled = true
		avatar.states.switch "default"

contactsScroll.draggable.enabled = true
contactsScroll.draggable.speedX = 0
contactsScroll.draggable.speedY = 0.5
mainScreen.sendToBack()
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
#HINTS
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
hintMask = new Layer
	superLayer: mainScreen
	x: 160-568*0.5, y: 336-568*0.5, width: 568, height: 568
	backgroundColor:'transparent', borderRadius: "50%"
hintMask.states.add hidden: { x: 160, y: 336, width: 0, height: 0 }
hintMask.states.switchInstant "hidden"
hintMask.sendToBack()
layers["hint1"].force2d = true
layers["hint1"].x = -(242-568)*0.5
layers["hint1"].y = 128
layers["hint1"].states.add hidden: { x: -242*0.5, y: 128-568*0.5}
layers["hint1"].states.switchInstant "hidden"
layers["hint1"].visible = false
layers["hint2"].force2d = true
layers["hint2"].x = -(260-568)*0.5
layers["hint2"].y = 272
layers["hint2"].visible = false
layers["hint2"].states.add hidden: { x: -260*0.5, y: 272-568*0.5}
layers["hint2"].states.switchInstant "hidden"
hintMask.addSubLayer layers["hint1"]
hintMask.addSubLayer layers["hint2"]

hint1Show = () ->
	hintMask.states.animationOptions = curve: materialCurveEnter, time: LONGANIMTIME
	layers["hint1"].states.animationOptions = curve: materialCurveEnter, time: LONGANIMTIME
	layers["hint2"].states.animationOptions = curve: materialCurveEnter, time: LONGANIMTIME
	hintMask.states.switch "default"
	layers["hint1"].visible = true
	layers["hint2"].visible = false
	layers["hint1"].states.switch "default"
	
hint2Show = () ->
	hintMask.states.animationOptions = curve: materialCurveEnter, time: LONGANIMTIME
	layers["hint1"].states.animationOptions = curve: materialCurveEnter, time: LONGANIMTIME
	layers["hint2"].states.animationOptions = curve: materialCurveEnter, time: LONGANIMTIME
	hintMask.states.switch "default"
	layers["hint1"].visible = false
	layers["hint2"].visible = true
	layers["hint2"].states.switch "default"
	
hintClose = () ->
	hintMask.states.animationOptions = curve: materialCurveEnter, time: SHORTANIMTIME
	layers["hint1"].states.animationOptions = curve: materialCurveEnter, time: SHORTANIMTIME
	layers["hint2"].states.animationOptions = curve: materialCurveEnter, time: SHORTANIMTIME
	hintMask.states.switch "hidden"
	layers["hint1"].states.switch "hidden"
	layers["hint2"].states.switch "hidden"

Utils.delay LONGANIMTIME, () ->
	if NUMBEROFCONTACTS is 1
		hint1Show()
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
#FAB
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
fab = new Layer
	superLayer: mainScreen
	x: 320-56-16, y: 568-56-16, width: 56, height: 56
	backgroundColor: "#ff6d00", borderRadius: "50%"
	shadowY: 2, shadowBlur:5, shadowColor: "rgba(0,0,0,0.3)"
fab.states.add
	hidden: {scale:0}
	new: {scale:1, x: (320-56)*0.5}
	send: {scale:1, x: (320-56)*0.5}
	next: {scale:1, x: (320-56)*0.5}
fab.states.switchInstant "hidden"

fabWhite = new Layer
	superLayer: fab
	x: 0, y: 0, width: 56, height: 56
	backgroundColor: "#fff", borderRadius: "50%"
fabWhite.states.add
	hidden: {scale:0}
fabWhite.states.switchInstant "hidden"
for i in ["fab_new_w", "fab_new", "fab_send", "fab_next"]
	fabIcon = new Layer
		superLayer: fab, name: i
		x: 14, y: 14, width: 28, height: 28, image: "./images/"+i+".png"
	fabIcon.states.add
		hidden: {rotation: 180, opacity: 0}
		hidden2: {rotation: -180, opacity: 0}
		default360: {rotation: 360}
fab.subLayersByName("fab_new")[0].states.switchInstant "hidden"
fab.subLayersByName("fab_send")[0].states.switchInstant "hidden"
fab.subLayersByName("fab_next")[0].states.switchInstant "hidden"

fab.on Events.Click, () ->
	hintClose()
	if fab.states.current is "default"
		avatar = makeAvatarForGrid(NUMBEROFCONTACTS)
		NUMBEROFCONTACTS++
		avatar.states.animationOptions = curve: materialCurveEnter
		avatar.states.switchInstant "default"
		contactsScroll.bubbleAvatarUp(NUMBEROFCONTACTS-1)
		
	else if fab.states.current is "send"
# 		console.log pointsX +"\n"+ pointsY +"\n"+ pointsNew
		contactsScroll.bubbleAvatarUp(drawScreen.avatar.position)
		drawScreen.drawView.send()
	else if fab.states.current is "next"
		drawScreen.drawView.next()
	else if fab.states.current is "new"
		drawScreen.drawView.new()
		
fab.on Events.StateWillSwitch, (prevState, currState) ->
	#FROM HIDDEN
	if prevState is "hidden" and currState is "new"
		fab.subLayersByName("fab_new_w")[0].states.switch "hidden2"
		fabWhite.states.switch "default"
		fab.subLayersByName("fab_new")[0].states.switchInstant "hidden"
		fab.subLayersByName("fab_new")[0].states.switch "default"
	if prevState is "hidden" and currState is "next"
		fab.subLayersByName("fab_new_w")[0].states.switch "hidden2"
		fabWhite.states.switch "default"
		fab.subLayersByName("fab_next")[0].states.switchInstant "hidden"
		fab.subLayersByName("fab_next")[0].states.switch "default"
	#FROM DEFAULT
	else if prevState is "default" and currState is "new"
		fab.subLayersByName("fab_new_w")[0].states.switch "hidden2"
		fabWhite.states.switch "default"
		fab.subLayersByName("fab_new")[0].states.switchInstant "hidden"
		fab.subLayersByName("fab_new")[0].states.switch "default"
	else if prevState is "default" and currState is "send"
		fab.subLayersByName("fab_new_w")[0].states.switch "hidden2"
		fabWhite.states.switch "default"
		fab.subLayersByName("fab_send")[0].states.switchInstant "hidden"
		fab.subLayersByName("fab_send")[0].states.switch "default"
	else if prevState is "default" and currState is "next"
		fab.subLayersByName("fab_new_w")[0].states.switch "hidden2"
		fabWhite.states.switch "default"
		fab.subLayersByName("fab_next")[0].states.switchInstant "hidden"
		fab.subLayersByName("fab_next")[0].states.switch "default"
	#FROM NEW
	else if prevState is "new" and currState is "default"
		fab.subLayersByName("fab_new")[0].states.switch "hidden"
		fabWhite.states.switch "hidden"
		fab.subLayersByName("fab_new_w")[0].states.switchInstant "hidden2"
		fab.subLayersByName("fab_new_w")[0].states.switch "default"
	else if prevState is "new" and currState is "send"
		fab.subLayersByName("fab_new")[0].states.switch "hidden2"
		fabWhite.states.switch "default"
		fab.subLayersByName("fab_send")[0].states.switchInstant "hidden"
		fab.subLayersByName("fab_send")[0].states.switch "default"
	#FROM SEND
	else if prevState is "send" and currState is "default"
		fab.subLayersByName("fab_send")[0].states.switch "hidden"
		fabWhite.states.switch "hidden"
		fab.subLayersByName("fab_new_w")[0].states.switchInstant "hidden2"
		fab.subLayersByName("fab_new_w")[0].states.switch "default"
	#FROM NEXT
	else if prevState is "next" and currState is "default"
		fab.subLayersByName("fab_next")[0].states.switch "hidden"
		fabWhite.states.switch "hidden"
		fab.subLayersByName("fab_new_w")[0].states.switchInstant "hidden2"
		fab.subLayersByName("fab_new_w")[0].states.switch "default"
	else if prevState is "next" and currState is "new"
		fab.subLayersByName("fab_next")[0].states.switch "hidden2"
		fabWhite.states.switch "default"
		fab.subLayersByName("fab_new")[0].states.switchInstant "hidden"
		fab.subLayersByName("fab_new")[0].states.switch "default"
	else if prevState is "next" and currState is "send"
		fab.subLayersByName("fab_next")[0].states.switch "hidden"
		fabWhite.states.switch "default"
		fab.subLayersByName("fab_send")[0].states.switchInstant "hidden2"
		fab.subLayersByName("fab_send")[0].states.switch "default"
	
if (NUMBEROFCONTACTS > 1)
	Utils.delay LONGANIMTIME*3, () ->
		fab.states.switch "default"
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
#NAVIGATION BAR
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
navbarTitle = new Layer
	superLayer: layers["NavigationBar"]
	x: 44, y: 20, width: 232, height: 48, backgroundColor: "transparent"
navbarTitle.style = LABELSTYLE
navbarTitle.style = textAlign: "center"
navbarTitle.states.add
	hidden: {scaleY: 0, opacity: 0}
navbarTitle.states.switchInstant "hidden"

navbarSwitch = (title) ->
	if title is undefined
		navbarTitle.states.switch "hidden"
	else
		navbarTitle.html = title
		navbarTitle.states.switch "default"

backFunction = (send = false) ->
	if NUMBEROFCONTACTS < 2
		Utils.delay LONGANIMTIME, hint2Show
	contactsScroll.visible = true
	contactsScroll.y = layers["settings_bar"].height
	drawScreen.drawView.backFunction()
	drawScreen.avatar.backFunction(send)
	navbarContactsState()
	fab.states.switch "default"
layers["back_button"].on Events.Click, backFunction

undoStroke = () ->
	layers["undo_button"].undoChain = Utils.delay 0.02, () ->
		canvasClear()
		canvasDelayedStroke(0)
		pointsX.pop()
		pointsY.pop()
		pointsNew.pop()
		undoStroke()
layers["undo_button"].on Events.TouchStart, undoStroke
layers["undo_button"].on Events.TouchEnd, () ->
	clearTimeout layers["undo_button"].undoChain
	
layers["reply_button"].on Events.Click, () ->
	drawScreen.drawView.reply()
layers["new_button"].on Events.Click, () ->
	drawScreen.drawView.new()
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
#NAVIGATIONBAR METHODS
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
navbarDrawingState = (title) ->
	layers["back_button"].states.switch "default"
	layers["back_button"].ignoreEvents = false
	navbarSwitch(title)
	layers["reply_button"].states.switch "hidden"
	layers["new_button"].states.switch "hidden"
	layers["undo_button"].states.switch "default"
	
navbarContactsState = (title) ->
	layers["back_button"].states.switch "hidden"
	navbarSwitch(title)
	layers["reply_button"].states.switch "hidden"
	layers["new_button"].states.switch "hidden"
	layers["undo_button"].states.switch "hidden"
		
navbarShowState = (title) ->
	layers["back_button"].states.switch "default"
	layers["back_button"].ignoreEvents = false
	navbarSwitch(title)
	layers["new_button"].states.switch "default"
	layers["undo_button"].states.switch "hidden"
	layers["reply_button"].states.switch "default"
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# AVATAR FOR CONTACTS
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
makeAvatarForGrid = (position) ->
	row = position
	
	avatar = new Layer
		superLayer: contactsScroll
		x: 0, y: 0, width: 320, height: AVATARSIZE, clip: true
		backgroundColor: "#fff"
	avatar.position = position
	avatar.states.add
		entering: {x: -320, opacity: 0, rotationZ: 0}
		exiting: {x: -320, opacity: 0, rotationZ: 0}
	avatar.states.switchInstant "entering"
	
	avatar.draggable.enabled = true
	avatar.draggable.speedX = 0.5
	avatar.draggable.speedY = 0
	
	avatar.on Events.DragMove, () ->
		velocity = @draggable.calculateVelocity()
		if Math.abs(velocity.x) > 0.1
			avatar.superLayer.draggable.enabled = false
		
	avatar.on Events.DragEnd, () ->
		avatar.superLayer.draggable.enabled = true
		swipeOffset = Math.abs(this.x)
		if swipeOffset > 320 * 0.66
			print "deleted"
		
	avatar.label = new Layer
		superLayer: avatar
		x: 0, y:0, width: avatar.width, height: avatar.height
		backgroundColor: "transparent"
	avatar.label.style =
		fontFamily: 'Coming Soon'
		fontSize: "40px", textAlign: "center", verticalAlign: "middle"
		lineHeight: avatar.height+"px"
		color: "#fff"
	
	avatar.messageLabel = new Layer
		superLayer: avatar
		x: 0, y: avatar.height-LABELHEIGHT, width: avatar.width, height: LABELHEIGHT
		backgroundColor: "transparent"
	avatar.messageLabel.style =
		fontFamily: "Coming Soon", lineHeight: LABELHEIGHT+"px",
		textAlign: "center", fontSize: "18px",
		fontWeight: 400, color: "#fff"
	avatar.messageLabel.html = ""
	
	avatar.updateMessageLabel = () ->
		if this.messageCount > 1
			this.messageLabel.html = this.messageCount + " nuovi messaggi"
		else if this.messageCount is 1
			this.messageLabel.html = this.messageCount + " nuovo messaggio"
		else
			this.messageLabel.html = ""
			
	if position < 1
		avatar.messageCount = 3
		avatar.updateMessageLabel()
		avatar.messageLabel.states.add
			hidden: {scale: 0, opacity: 0}
			pop: {scale: 1.2, opacity: 1}
		avatar.messageLabel.states.switchInstant "hidden"
		Utils.delay position*0.2+LONGANIMTIME, () ->
			avatar.messageLabel.states.switch "pop"
		avatar.messageLabel.on Events.StateDidSwitch, (prevState, currState) ->
			if prevState is "hidden" and currState is "pop"
				avatar.messageLabel.states.switch "default"
	else
		avatar.messageCount = 0
				
	if position is 0
		avatar.label.html = MASCOTTE_NAME
	else
		avatar.label.html = CONTACTS().name

	avatar.backgroundColor = CONTACTS_COLORS[position%CONTACTS_COLORS.length]
	
	avatar.clickFunction = () ->
		if this.draggable.enabled
			swipeOffset = Math.abs(this.x)
			if swipeOffset is 0
				#CLICK
				hintClose()
				if this.messageCount <= 0
					#DRAW SCREEN
					navbarDrawingState()
					openDrawScreen(this)
					canvasClear(true)
					fab.states.switch "send"
				else
					#SHOW SCREEN
					navbarShowState()
					openShowScreen(this)
					if this.messageCount > 1
						fab.states.switch "next"
					else
						fab.states.switch "new"
				
	avatar.on Events.Click, avatar.clickFunction
				
	contactsScroll.height = contactsScroll.height+avatar.height
	avatar

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# AVATAR FOR DRAWING
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
makeAvatarForDrawing = (gridAvatar) ->
	avatar = new Layer
		superLayer: drawScreen
		x: gridAvatar.x, y: gridAvatar.y+contactsScroll.y
		width: 320, height: AVATARSIZE, clip: false, backgroundColor: gridAvatar.style.backgroundColor
	avatar.position = gridAvatar.position
	avatar.states.add
		maximized: {	x: 0, y: 0, width: 320, height: 568 }
		send: {	x: 0, y: layers["settings_bar"].targetHeight, width: 320, height: AVATARSIZE }
	avatar.states.switch "maximized"
	
	avatar.label = new Layer
		superLayer: avatar
		x: gridAvatar.label.x, y:gridAvatar.label.y
		width: gridAvatar.label.width, height: gridAvatar.label.height
		opacity: gridAvatar.label.opacity
	avatar.label.html = gridAvatar.label.html
	avatar.label.style = gridAvatar.label.style
	avatar.label.states.add
		top: {scale: 0.5, y: -8}
	avatar.label.states.switch "top"
	
	avatar.on Events.StateDidSwitch, (prevState, currState) ->
		#DRAW SCREEN: AFTER SEND MESSAGE CLEANUP
		if currState is "default" or currState is "send"
			navbarContactsState()
			drawScreen.avatar.destroy()
			
	avatar.backFunction = (send = false) ->
		if send is true
			avatar.states.switch "send"
		else
			avatar.states.switch "default"
		avatar.label.states.switch "default"
	avatar

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# PAPER FOR DRAWING
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
makeDrawPaper = () ->
	drawPaper = new Layer
		superLayer: drawScreen
		x: (320-SHEETSIZE)*0.5, y: (568-SHEETSIZE)*0.5
		width: SHEETSIZE, height: SHEETSIZE, scale: 1
		backgroundColor: "#fff", borderRadius: "4px"
		shadowY: 2, shadowBlur:1, shadowColor: "rgba(0,0,0,0.3)"
	
	drawPaper._element.appendChild(canvas);
	drawPaper.ignoreEvents = false
	
	drawPaper.states.add
		hidden: { y: 568*0.5+SHEETSIZE*0.25, scale: 0, opacity: 0 }
		destroy: { y: 568*0.5+SHEETSIZE*0.25, scale: 0, opacity: 0 }
		minimized: { scaleX: 50/SHEETSIZE }
		send: { y: 568-(50+SHEETSIZE)*0.5-16, scaleY: 0 }
		turn: { brightness: 50, scale:1, scaleY:0}
	drawPaper.states.switchInstant "hidden"
	drawPaper.states.animationOptions = curve: materialCurveEnter
	
	drawPaper.on Events.StateWillSwitch, (prevState, currState) ->
		if prevState is "hidden" and currState is "default"
			this.infoLabel.states.switch "default"
		else if currState is "destroy"
			this.infoLabel.states.switch "hidden"
		
	drawPaper.on Events.StateDidSwitch, (prevState, currState) ->
		if prevState is "default" and currState is "minimized"
			this.states.animationOptions = curve: materialCurveExit
			this.states.switch "send"
		else if prevState is "minimized" and currState is "send"
			backFunction(true)
		else if currState is "destroy"
			this.infoLabel.destroy()
			this.destroy()
	
	drawPaper.states.animationOptions =
		curve: materialCurveEnter
		time: LONGANIMTIME
		
	# CREATE TIME INFO LABEL
	drawPaper.infoLabel = new Layer
		x: 0, y: fab.y-72, width: 320, height: 72
		backgroundColor: "transparent"
	drawPaper.infoLabel.style =
		fontFamily: "Coming Soon", lineHeight: '72px',
		textAlign: "center", verticalAlign: "middle"
		fontSize: "24px", color: '#fff', 
	drawPaper.infoLabel.html = "Invia disegno"
	drawPaper.infoLabel.states.add
		hidden: {scaleY: 0, opacity: 0}
	drawPaper.infoLabel.states.switchInstant "hidden"
		
	drawPaper.send = () ->
		this.states.animationOptions = curve: materialCurveMove
		this.states.switch "minimized"
		
	drawPaper.backFunction = () ->
		this.states.animationOptions = curve: materialCurveExit, time: SHORTANIMTIME
		this.states.switch "destroy"
		
	#CREATE CANVAS, ADD LISTENERS
	canvas.width = SHEETSIZE
	canvas.height = SHEETSIZE
	
	canvas.addEventListener("mousedown", canvasDown, false);
	canvas.addEventListener("mousemove", canvasMove, false);
	canvas.addEventListener("mouseup", canvasUp, false);
	
	drawPaper

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# PAPER FOR SHOWING
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
makeShowPaper = (messageCount) ->
	showPaper = new Layer
		superLayer: drawScreen
		x: (320-SHEETSIZE)*0.5, y: (568-SHEETSIZE)*0.5
		width: SHEETSIZE, height: SHEETSIZE, scale: 1
		backgroundColor: "#fff", borderRadius: "4px", clip: false
		shadowY: 2, shadowBlur:1, shadowColor: "rgba(0,0,0,0.3)"
	showPaper.consumed = false
		
	showPaper.states.add
		hidden: {y: 568*0.5-SHEETSIZE*1.25, scale: 0, opacity: 0 }
		destroyTop: {y: 568*0.5-SHEETSIZE*1.25, scale: 0, opacity: 0 }
		destroyLeft: { x: SHEETSIZE * 0.5 - 560, rotation: -2.5}
		picked: { midY: 568*0.5-8, shadowY: 10, shadowBlur:10 }
		default2: { midX: 160, midY: 568*0.5, scale: 1, opacity: 1, rotation: 0, shadowY: 2, shadowBlur: 1 }
		exit: { x: SHEETSIZE * 0.5 - 560, rotation: -2.5}
		enter: { x: SHEETSIZE * 0.5 + 560, rotation: 2.5}
		replyNew: { x: SHEETSIZE * 0.5 - 560, rotation: -2.5}
		replyOver: { brightness: 75, scaleY:0}
	showPaper.states.switchInstant "hidden"
	
	showPaper.on Events.StateWillSwitch, (prevState, currState) ->
		if prevState is "hidden" or prevState is "enter" and currState is "default"
			this.timeInfoLabel.states.switch "default"
			this.tail.states.animationOptions = time: SHORTANIMTIME, curve: materialCurveEnter
			this.tail.states.switch "default"
			this.paging.states.switch "default"
		else if currState is "replyOver"
			this.instantDraw()	#INSTANTLY COMPLETE THE DRAWING
		else if currState is "picked"
			this.tail.states.animationOptions = time: SHORTANIMTIME, curve: materialCurveExit
			this.tail.states.switch "hidden"
			this.timeInfoLabel.states.switch "hidden"
			
			this.instantDraw()	#INSTANTLY COMPLETE THE DRAWING
			this.consumed = true
		else if prevState is "picked" and currState is "default2"
			this.tail.states.animationOptions = time: SHORTANIMTIME, curve: materialCurveEnter
			this.tail.states.switch "default"
			this.timeInfoLabel.states.switch "default"
		else if currState is "destroyTop" or currState is "destroyLeft"
			this.paging.states.switch "hidden"
			this.timeInfoLabel.states.switch "hidden"
	
	showPaper.on Events.StateDidSwitch, (prevState, currState) ->
		if prevState is "exit" and currState is "enter"
			#ENTER THE NEW SHOWPAPER
			this.states.animationOptions = time: LONGANIMTIME, curve: materialCurveEnter
			this.states.switch "default"
			#UPDATE TIME LABEL
			messageCount = contactsScroll.getAvatarByPosition(drawScreen.avatar.position).messageCount
			this.timeInfoLabel.html = "Inviato "+(messageCount*5)+" minuti fa"
			this.timeInfoLabel.states.switch "default"
			this.consumed = false
			canvasClear(true)
			canvasLoadCustomDrawing(CUSTOMDRAWINGS.length - messageCount) #SHOW NEW PAPER
			canvasDelayedStroke()	 #START DRAWING AGAIN
		else if currState is "exit"
			if this.paging.subLayers.length > 3
				this.states.switchInstant "enter"
			else
				this.toDrawScreen()
		else if currState is "replyNew"or currState is "replyOver"
			this.toDrawScreen(currState is "replyOver")
		else if currState is "destroyTop" or currState is "destroyLeft"
			this.paging.destroy()
			this.timeInfoLabel.destroy()
			this.destroy()
	
	showPaper.draggable.enabled = true
	showPaper.draggable.speedX = 0.5
	showPaper.draggable.speedY = 0
	
	showPaper.tail = new Layer
		superLayer: showPaper, originX: 0.5, originY: 1
		x: (SHEETSIZE-48)*0.5, y: -32+1, width: 48, height: 32
		image: "images/balloon_tail.png"
	showPaper.tail.states.add
		hidden: {opacity: 0, scale: 0}
	showPaper.tail.states.switchInstant "hidden"
	
	# CREATE TIME INFO LABEL
	showPaper.timeInfoLabel = new Layer
		x: 0, y: 64, width: 320, height: LABELHEIGHT*0.5
		backgroundColor: "transparent"
	showPaper.timeInfoLabel.style =
		fontFamily: "Coming Soon", textAlign: "center", verticalAlign: "top"
		fontSize: "16px", color: '#fff', 
	showPaper.timeInfoLabel.html = (messageCount*5)+" minuti fa"
	showPaper.timeInfoLabel.states.add
		hidden: {scaleY: 0, opacity: 0}
	showPaper.timeInfoLabel.states.switchInstant "hidden"
	
	# CREATE INFO LABEL
	showPaper.infoLabel = new Layer
		x: 0, y: 64, width: 320, height: 72
		backgroundColor: "transparent"
	showPaper.infoLabel.style =
		fontFamily: "Coming Soon", lineHeight: '72px',
		textAlign: "center", verticalAlign: "middle"
		fontSize: "32px", color: '#fff', 
	showPaper.infoLabel.states.add
		hidden: {scaleY: 0, opacity: 0}
		selected: {scaleY: 1, scale: 2, opacity: 0}
	showPaper.infoLabel.states.switchInstant "hidden"
	
	# Drag start
	showPaper.on Events.DragStart, (event, showPaper) ->
		showPaper.states.animationOptions = time: SHORTANIMTIME, curve: materialCurveMove
		showPaper.states.switch "picked"
	
	# Drag move
	showPaper.on Events.DragMove, (event, showPaper) ->
		distX = showPaper.x + SHEETSIZE * 0.5 - 160
		unitValue = Utils.modulate(Math.abs(distX), [20, 60], [0, 1], true)
		rotValue = Utils.modulate(distX, [-160, 160], [-2.5, 2.5], false)
		if distX < 0
			if showPaper.paging.subLayers.length > 3
				showPaper.infoLabel.html = "Disegno successivo"
				layers["next_icon"].minX = Math.max(160-layers["next_icon"].width*0.5, showPaper.maxX + 32)
				layers["next_icon"].opacity = unitValue
				layers["next_icon"].scale = 1
			else
				showPaper.infoLabel.html = "Invia nuovo disegno"
				layers["new_icon"].minX = Math.max(160-layers["new_icon"].width*0.5, showPaper.maxX + 32)
				layers["new_icon"].opacity = unitValue
				layers["new_icon"].scale = 1
		else
			showPaper.infoLabel.html = "Replay"
			layers["replay_icon"].maxX = Math.min(160+layers["replay_icon"].width*0.5, showPaper.minX - 32)
			layers["replay_icon"].opacity = unitValue
			layers["replay_icon"].scale = unitValue
		showPaper.rotation = rotValue
		showPaper.y = (568-SHEETSIZE)*0.5-8
		showPaper.infoLabel.scaleY = unitValue
		showPaper.infoLabel.opacity = showPaper.infoLabel.scale = 1
	
	showPaper.on Events.DragEnd, (event) ->
		distX = showPaper.midX - 160
		if distX < -106
			showPaper.next()
		else if distX > 106
			showPaper.redraw()
		else
			showPaper.undoSwipeAction()
	
	showPaper.paging = new Layer
		x: 160-(8*(messageCount*2+3)*0.5), y: (568+SHEETSIZE)*0.5+16, width: 8, height: 8
		backgroundColor: "transparent", clip: false
	showPaper.paging.states.add
		hidden: {scaleY: 0, opacity: 0}
	showPaper.paging.states.switchInstant "hidden"
	
	layers["paging_replay"].superLayer = showPaper.paging
	layers["paging_replay"].x = -2
	layers["paging_replay"].y = -2
	layers["paging_replay"].states.switchInstant "default"
	layers["paging_replay"].opacity = 0.5
	
	for i in [0..messageCount-1]
		opc = 0.5
		if i is 0
			opc = 1
		new Layer
			superLayer: showPaper.paging
			x: 8*(i+1)*2, y: 0, width: 8, height: 8, borderRadius: 4
			backgroundColor: "#fff", opacity: opc
			
	layers["paging_new"].superLayer = showPaper.paging
	layers["paging_new"].x = 8*(i+1)*2 - 2
	layers["paging_new"].y = -2
	layers["paging_new"].states.switchInstant "default"
	layers["paging_new"].opacity = 0.5
	
	showPaper.paging.width = showPaper.paging.contentFrame().width
	showPaper.paging.nextDrawing = () ->
		#ANIMATE THE PAGING DOTS
		for i in [1..showPaper.paging.subLayers.length-1]
			if i is 1
				#RELOAD ICON
				showPaper.paging.animate
					properties:
						x: showPaper.paging.x + 8
					curve: materialCurveMove
					time: LONGANIMTIME
				shiftAnim = showPaper.paging.subLayers[i].animate
					properties:
						scale: 0
						x: 8*(i-1)*2
					curve: materialCurveMove
					time: LONGANIMTIME
				shiftAnim.on Events.AnimationEnd, () ->
					showPaper.paging.removeSubLayer(showPaper.paging.subLayers[1])
			else if i < showPaper.paging.subLayers.length-1
				#DOTS
				opc = 0.4
				if i is 2
					opc = 0.8
				showPaper.paging.subLayers[i].animate
					properties:
						x: 8*(i-1)*2
						opacity: opc
					curve: materialCurveMove
					time: LONGANIMTIME
			else
				#NEW DRAWING
				showPaper.paging.subLayers[i].animate
					properties:
						x: 8*(i-1)*2 - 2
						opacity: 0.4
					curve: materialCurveMove
					time: LONGANIMTIME
				
	showPaper.backFunction = () ->
		#STOP ANIMATED STROKE
		showPaper.states.animationOptions = curve: materialCurveExit, time: SHORTANIMTIME
		if this.consumed is true or window.delayedStrokeTimeout is null
			this.decreaseAvatarMessageCount()
			this.states.switch "destroyLeft"
		else
			clearTimeout(window.delayedStrokeTimeout)
			window.delayedStrokeTimeout = null
			this.states.switch "destroyTop"
	
	showPaper.decreaseAvatarMessageCount = () ->
		avatar = contactsScroll.getAvatarByPosition(drawScreen.avatar.position)
		avatar.messageCount--
		avatar.updateMessageLabel()
	
	showPaper.redraw = () ->
		this.infoLabel.states.switch "selected"
		layers["replay_icon"].states.switch "selected"
		canvasClear()	#CLEAR CANVAS
		Utils.delay LONGANIMTIME, canvasDelayedStroke #REDRAW THE SAME DRAWING
		this.states.animationOptions = time: LONGANIMTIME, curve: materialCurveMove
		this.states.switch "default2"
		this.timeInfoLabel.states.switch "default"
		
	showPaper.next = () ->
		this.infoLabel.states.switch "selected"
		layers["next_icon"].states.switch "selected"
		layers["new_icon"].states.switch "selected"
		#STOP ANIMATED STROKE
		if window.delayedStrokeTimeout isnt null
			clearTimeout(window.delayedStrokeTimeout)
			window.delayedStrokeTimeout = null
		#REQUEST A NEW DRAWING
		this.states.animationOptions = time: SHORTANIMTIME, curve: materialCurveExit
		this.states.switch "exit"
		this.decreaseAvatarMessageCount()
		#PAGING: NEXT ITEM
		this.timeInfoLabel.states.switch "hidden"
		this.paging.nextDrawing()
		if contactsScroll.getAvatarByPosition(drawScreen.avatar.position).messageCount is 1
			fab.states.switch "new"
			
	showPaper.new = () ->
		#NEW ALWAYS CONSUME THE DRAWING, LIKE NEXT
		this.instantDraw()
		this.decreaseAvatarMessageCount()
		this.states.animationOptions = curve: materialCurveExit
		this.states.switch "replyNew"
		#CHANGE TO DRAWING SCREEN
		this.paging.states.switch "hidden"
		fab.states.switch "send"
		
	showPaper.reply = () ->
		#STOP ANIMATED STROKE
		if this.consumed is true or window.delayedStrokeTimeout is null
			#THE DRAWING WAS CONSUMED
			this.decreaseAvatarMessageCount()
		else
			clearTimeout(window.delayedStrokeTimeout)
			window.delayedStrokeTimeout = null
		#CHANGE TO DRAWING SCREEN
		this.states.animationOptions = curve: materialCurveExit
		this.states.switch "replyOver"
		this.paging.states.switch "hidden"
		fab.states.switch "send"
			
	showPaper.undoSwipeAction = () ->
		this.states.animationOptions = time: SHORTANIMTIME, curve: materialCurveMove
		this.states.switch "default2"
		this.infoLabel.states.switch "hidden"
		for i in ["replay_icon", "next_icon", "new_icon"]
			layers[i].states.switch "hidden"
	
	showPaper.instantDraw = () ->
		#STOP ANIMATED STROKE
		if window.delayedStrokeTimeout isnt null
			clearTimeout(window.delayedStrokeTimeout)
			window.delayedStrokeTimeout = null
		#CLEAR CANVAS AND DRAW THE WHOLE DRAWING
		canvasClear()
		canvasDelayedStroke(0)
	
	showPaper.toDrawScreen = (drawOver = false) ->
		#ENTER NEW DRAWING SCREEN
		showPaper.paging.states.switch "hidden"
		showPaper.timeInfoLabel.states.switch "hidden"
		navbarDrawingState()
		drawScreen.drawView = makeDrawPaper()
		fab.states.switch "send"
		if drawOver
			canvasDelayedStroke(0)
			drawScreen.drawView.states.switchInstant "turn"
			drawScreen.drawView.states.switch "default"
		else
			canvasClear(true)
			drawScreen.drawView.states.switch "default"
		
	#CREATE CANVAS, REMOVE LISTENERS
	canvas.width = SHEETSIZE
	canvas.height = SHEETSIZE
	
	canvas.removeEventListener("mousedown", canvasDown, false);
	canvas.removeEventListener("mousemove", canvasMove, false);
	canvas.removeEventListener("mouseup", canvasUp, false);
	
	showPaper._element.appendChild(canvas);
	showPaper.ignoreEvents = false
	
	showPaper

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
#CANVAS VARIABLES FOR GLOBAL ACCESS
canvas = document.createElement("canvas");
context = canvas.getContext("2d");

pointsX = []
pointsY = []
pointsNew = []

#CANVAS METHODS
canvasDown = (e) ->
	canvas.paint = true
	pointsX.push(e.offsetX);
	pointsY.push(e.offsetY);
	pointsNew.push(true);
	canvasDelayedStroke(0)
		
canvasMove = (e) ->
	if canvas.paint
		pointsX.push(e.offsetX);
		pointsY.push(e.offsetY);
		pointsNew.push(false);
		canvasDelayedStroke(0)
		
canvasUp = (e) ->
	canvas.paint = false
	canvasDelayedStroke(0)

canvasClear = (clearPoints = false) ->
	context.clearRect 0, 0, canvas.width, canvas.height
	if clearPoints
		pointsX = []
		pointsY = []
		pointsNew = []

canvasCreateRandomSequence = (t = 1) ->
	pointsX = []
	pointsY = []
	angle = Utils.randomNumber(0,2 * Math.PI)
	pointsX.push(canvas.width*0.5)
	pointsY.push(canvas.height*0.5)
	while t > 0
		angle = angle + Utils.randomNumber(-Math.PI/9, Math.PI/9)
		lastX = pointsX[pointsX.length-1]
		lastY = pointsY[pointsY.length-1]
		if lastX <= STROKEWIDTH or lastX >= canvas.width-STROKEWIDTH or lastY <= STROKEWIDTH or lastY >= canvas.height-STROKEWIDTH
			angle = angle + Math.PI
		pointsX.push( (lastX + Math.cos(angle)*5)|0 )
		pointsY.push( (lastY + Math.sin(angle)*5)|0 )
		t = t - 1
		
canvasLoadCustomDrawing = (drawIndex) ->
	pointsX = CUSTOMDRAWINGS[drawIndex].x.slice()
	pointsY = CUSTOMDRAWINGS[drawIndex].y.slice()
	pointsNew = CUSTOMDRAWINGS[drawIndex].n.slice()

window.delayedStrokeTimeout = null
canvasDelayedStroke = (delay = PLAYDURATION/pointsX.length, i=0) ->
	if delay is 0
		window.delayedStrokeTimeout = null
		canvasStroke(i)
		if i < pointsX.length-2
			canvasDelayedStroke(delay, i+1)
	else
		window.delayedStrokeTimeout = Utils.delay delay, () ->
			canvasStroke(i)
			if i < pointsX.length-2
				canvasDelayedStroke(delay, i+1)
			else
				window.delayedStrokeTimeout = null

canvasStroke = (i) ->
	context.beginPath()
	context.lineCap = "round"
	context.lineWidth = STROKEWIDTH
	if (!pointsNew[i])
		context.moveTo pointsX[i], pointsY[i]
	if (!pointsNew[i+1])
		context.lineTo pointsX[i+1], pointsY[i+1]
	context.stroke()

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# OPEN DRAW SCREEN
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
openDrawScreen = (clickedAvatar) ->
	canvasClear()
	drawScreen.avatar = makeAvatarForDrawing(clickedAvatar)
	drawScreen.drawView = makeDrawPaper()
	
	Utils.delay LONGANIMTIME*0.5, () ->
		contactsScroll.visible = false
		drawScreen.drawView.states.switch "default"

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# OPEN SHOW SCREEN
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
openShowScreen = (clickedAvatar) ->
	canvasClear()
	drawScreen.avatar = makeAvatarForDrawing(clickedAvatar)
	drawScreen.drawView = makeShowPaper(clickedAvatar.messageCount)
	
	Utils.delay LONGANIMTIME*0.5, () ->
		contactsScroll.visible = false
		drawScreen.drawView.states.switch "default"
	Utils.delay LONGANIMTIME*2, () ->
		if clickedAvatar.label.html is MASCOTTE_NAME
			canvasLoadCustomDrawing(CUSTOMDRAWINGS.length - clickedAvatar.messageCount)
		else
			canvasCreateRandomSequence(500)
		canvasDelayedStroke()		

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
#MAKE LAYERS
for i in [0..NUMBEROFCONTACTS-1]
	avatar = makeAvatarForGrid(i)
	contactsScroll.sortAvatars()
	avatar.states.animationOptions =
		curve: materialCurveEnter
		delay: i * 0.1
	avatar.states.switch "default"