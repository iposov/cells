/**
 * Created with IntelliJ IDEA.
 * User: ilya
 * Date: 26.03.13
 * Time: 13:03
 */
package view {
import flash.desktop.Clipboard;
import flash.desktop.ClipboardFormats;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.Timer;

import model.Area;

public class AreaView extends Sprite {

    public static const MAXIMIZED:String = 'event maximized';

    private static const borderSize1:int = 1;
    private static const borderSize2:int = 2;
    private static const borderColor:uint = 0x000000;

    private static const TYPE_COLORS:Array = [0xfffdaf, 0x505050, 0x507050, 0xddffdd];
    private static const TYPE_ALPHA:Number = 1;

    private var _field:Sprite = new Sprite();
    private var _area:Area;
    private var _cellSize:int = 20;

    private var startDragStageX:Number = -1;
    private var startDragStageY:Number = -1;

    private var startDragField:Boolean = false;

    private const _showHints:Boolean = true;

    private var _title:String;

    private var _normalX:int = -1;
    private var _normalY:int = -1;
    private var _normalWidth:int;
    private var _normalHeight:int;
    private var _openX:int;
    private var _openY:int;
    private var _openWidth:int;
    private var _openHeight:int;
    private var _maximized:Boolean = false;

    private var evalTextField:TextField;
    private var tooltip:Sprite;
    private var tooltipText:TextField;

    private var selectingRectangle:Boolean = false;
    private var selectingRectangleAdd:Boolean;
    private var selectingRectanglePoint:int = 0;
    private var selectingRectangle1stPoint:Point; //TODO report 'convert to local'

    public function AreaView(area:Area, mergers:Array, title:String, normalWidth:int, normalHeight:int, openX:int, openY:int, openWidth:int, openHeight:int) {
        _area = area;

        _title = title;
        _normalWidth = normalWidth;
        _normalHeight = normalHeight;
        _openX = openX;
        _openY = openY;
        _openWidth = openWidth;
        _openHeight = openHeight;

        _field.addEventListener(MouseEvent.MOUSE_DOWN, field_mouseDownHandler);
        addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);

        _area.addEventListener(Event.CHANGE, areaChangeHandler);
        _area.addEventListener(Area.SOURCE_CHANGE_EVENT, areaChangeHandler);

        initView(normalWidth, normalHeight);

        redrawField();
    }

    private function isMerging():Boolean {
        return false;
    }

    public function get area():Area {
        return _area;
    }

    private function initView(width:int, height:int):void {
        while (numChildren > 0)
            removeChildAt(0);

        graphics.clear();

        //create mask
        var mask:Shape = new Shape();
        mask.graphics.beginFill(0x000000);
        mask.graphics.drawRect(borderSize2, borderSize2, width - 2 * borderSize2, height - 2 * borderSize2);
        mask.graphics.endFill();
        addChild(mask);

        //draw border
        graphics.lineStyle(borderSize1, borderColor);
        graphics.drawRect(0, 0, width, height);

        _field.mask = mask;
        addChild(_field);

        //maximize & minimize button
        var maxmin:Sprite = Button.createSprite(20, 14, 0xCCCCCC);
        maxmin.addEventListener(MouseEvent.CLICK, maxmin_clickHandler);
        maxmin.x = width - 20;
        maxmin.y = -16;
        addChild(maxmin);

        //draw title
        var titleField:TextField = new TextField();
        titleField.defaultTextFormat = new TextFormat('Arial', 14);
        titleField.autoSize = TextFieldAutoSize.LEFT;
        titleField.selectable = false;
        addChild(titleField);
        titleField.x = 0;
        titleField.y = -20;
        titleField.text = _title;

        //remove button
        var removeButton:Sprite = Button.createSprite(80, 14, 0xCCCCCC, 'Clear', 0, -2);
        removeButton.x = width - 80;
        removeButton.y = height + 4;
        removeButton.doubleClickEnabled = true;
        TextField(removeButton.getChildAt(0)).doubleClickEnabled = true;
        addChild(removeButton);
        removeButton.addEventListener(MouseEvent.DOUBLE_CLICK, removeButton_clickHandler);

        //button - center origin
        var centerOriginButton:Sprite = Button.createSprite(80, 14, 0xCCCCCC, 'To center', -1, -2);
        centerOriginButton.x = 0;
        centerOriginButton.y = height + 4;
        addChild(centerOriginButton);
        centerOriginButton.addEventListener(MouseEvent.CLICK, centerOrigin_clickHandler);

        //buttons to zoom in and zoom out
        var zoomIn:Sprite = Button.createSprite(20, 14, 0xCCCCCC, '+', -1, -2);
        zoomIn.x = centerOriginButton.x + centerOriginButton.width + 4;
        zoomIn.y = height + 4;
        addChild(zoomIn);
        var zoomOut:Sprite = Button.createSprite(20, 14, 0xCCCCCC, '-', -1, -2);
        zoomOut.x = zoomIn.x + zoomIn.width + 4;
        zoomOut.y = height + 4;
        addChild(zoomOut);
        zoomIn.addEventListener(MouseEvent.CLICK, zoomIn_clickHandler);
        zoomOut.addEventListener(MouseEvent.CLICK, zoomOut_clickHandler);

        //button evaluate
        var evalButton:Sprite = Button.createSprite(80, 14, 0xCCCCCC, 'Eval', -1, -2);
        evalButton.x = zoomOut.x + zoomOut.width + 4;
        evalButton.y = height + 4;
        addChild(evalButton);
        evalButton.addEventListener(MouseEvent.CLICK, evalButton_clickHandler);

        //eval text field
        evalTextField = new TextField();
        evalTextField.defaultTextFormat = new TextFormat('Arial', 14);
        evalTextField.autoSize = TextFieldAutoSize.LEFT;
        evalTextField.x = evalButton.x + evalButton.width + 4;
        evalTextField.y = height + 2;
        addChild(evalTextField);

        //create tooltip

        initTooltip();
        _field.addEventListener(MouseEvent.MOUSE_MOVE, field_mouseMoveHandler);
        _field.addEventListener(MouseEvent.ROLL_OUT, field_rollOutHandler);
    }

    private function initTooltip():void {
        if (tooltip != null)
            _field.removeChild(tooltip);

        tooltip = Button.createSprite(200, isMerging() ? /*54*/ 20 : 20, 0x00ff00, '', -1, -9);
        tooltipText = TextField(tooltip.getChildAt(0));
        tooltipText.multiline = true;
        tooltip.visible = false;
        tooltip.mouseEnabled = false;
        _field.addChild(tooltip);
    }

    private function areaChangeHandler(event:Event):void {
        redrawField();
        updateEvaluationInfo();
    }

    private function redrawField():void {
        var g:Graphics = _field.graphics;

        g.clear();

        const N:int = 500;

        g.beginFill(0xFFFFFF);
        g.drawRect(-N * _cellSize, -N * _cellSize, 2 * N * _cellSize, 2 * N * _cellSize);
        g.endFill();

        g.lineStyle(1, 0x888888, 0.5);

        for (var x:int = -N; x <= N; x++) {
            g.moveTo(x * _cellSize, -N * _cellSize);
            g.lineTo(x * _cellSize, N * _cellSize);
        }

        for (var y:int = -N; y <= N; y++) {
            g.moveTo(-N * _cellSize, y * _cellSize);
            g.lineTo(N * _cellSize, y * _cellSize);
        }

        //draw cells

        drawCells();

        //mark source
        for (var src:int = 0; src < 2; src++)
            if (_area.hasSource(src)) {
                var p:Point = logical2screen(_area.getSourceX(src), _area.getSourceY(src));
                g.lineStyle(2, src == 0 ? 0xFF0000 : 0x0000FF);
                g.drawRect(p.x, p.y, _cellSize, _cellSize);
            }
    }

    private function drawCells():void {
        var g:Graphics = _field.graphics;
        g.lineStyle(2, 0x000000);
        for each (var xy:Array in _area.cells) {
            var p:Point = logical2screen(xy[0], xy[1]);
            g.beginFill(TYPE_COLORS[_area.cellType(xy[0], xy[1])], TYPE_ALPHA);
            g.drawRect(p.x, p.y, _cellSize, _cellSize);
            g.endFill();
        }
    }

    private function field_mouseDownHandler(event:MouseEvent):void {
        if (event.shiftKey && event.ctrlKey) {
            if (tooltip.visible)
                {
                    var clpValue:String = tooltipText.text;
//                    if (!isMerging())
                    clpValue = clpValue.substring('XX: '.length);
                    Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, clpValue);
                }
            return;
        }

        if (! isMerging()) {

            if (selectingRectanglePoint == 1) {
                selectingRectangle1stPoint = new Point(event.localX, event.localY);
                selectingRectanglePoint = 2;
                evalTextField.text = 'Выберите вторую клетку';
                return;
            } else if (selectingRectanglePoint == 2) {
                selectingRectanglePoint = 0;
                var p1:Point = screen2logical(selectingRectangle1stPoint.x, selectingRectangle1stPoint.y);
                var p2:Point = screen2logical(event.localX, event.localY);
                if (selectingRectangleAdd)
                    _area.addRectangle(p1.x, p1.y, p2.x, p2.y);
                else
                    _area.removeRectangle(p1.x, p1.y, p2.x, p2.y);
                return;
            }

            if (event.shiftKey || event.ctrlKey) {
                var p:Point = screen2logical(event.localX, event.localY);
                if (event.shiftKey)
                    _area.setOrigin(p.x, p.y);
                else {
                    if (event.altKey)
                        _area.setSource(1, p.x, p.y);
                    else
                        _area.setSource(0, p.x, p.y);
                }
                return;
            }
        }

        //no keybord used, do drag or a single click
        _field.startDrag();

        startDragField = true;

        startDragStageX = event.stageX;
        startDragStageY = event.stageY;
    }

    private function field_mouseUpHandler(event:MouseEvent):void {
        if (!startDragField)
            return;

        startDragField = false;

        _field.stopDrag();

        if (Math.abs(startDragStageX - event.stageX) + Math.abs(startDragStageY - event.stageY) <= 2 && ! isMerging())
            fieldClick(event);
    }

    private function fieldClick(event:MouseEvent):void {
        var point:Point = screen2logical(event.localX, event.localY);

        if (_area.hasCell(point.x, point.y))
            _area.removeCell(point.x, point.y);
        else
            _area.addCell(point.x, point.y);
    }

    public function screen2logical(x:Number, y:Number):Point {
        x = Math.floor(x / _cellSize);
        y = - Math.floor(y / _cellSize);

        return new Point(x, y);
    }

    public function logical2screen(x:Number, y:Number):Point {
        return new Point(x * _cellSize, -y * _cellSize);
    }

    private function addedToStageHandler(event:Event):void {
        stage.addEventListener(MouseEvent.MOUSE_UP, field_mouseUpHandler);
    }

    private function maxmin_clickHandler(event:MouseEvent):void {
        if (_maximized) {
            x = _normalX;
            y = _normalY;
            var width:int = _normalWidth;
            var height:int = _normalHeight;

            _maximized = false;
        } else {
            _normalX = x;
            _normalY = y;

            x = _openX;
            y = _openY;
            width = _openWidth;
            height = _openHeight;

            _maximized = true;
        }

        initView(width, height);

        dispatchEvent(new Event(MAXIMIZED));
    }

    public function get maximized():Boolean {
        return _maximized;
    }

    private function removeButton_clickHandler(event:MouseEvent):void {
        _area.clear();
    }

    private function centerOrigin_clickHandler(event:MouseEvent):void {
        var ox:int = _area.originX;
        var oy:int = _area.originY;

        moveCellToCenter(ox, oy);
    }

    private function moveCellToCenter(x:int, y:int):void {
        var op:Point = logical2screen(x, y);
        //op -> width / 2, height / 2

        _field.x = currentWidth / 2 - op.x;
        _field.y = currentHeight / 2 - op.y;
    }

    private function get currentHeight():int {
        return _maximized ? _openHeight : _normalHeight;
    }

    private function get currentWidth():int {
        return _maximized ? _openWidth : _normalWidth;
    }

    private function zoomIn_clickHandler(event:MouseEvent):void {
        if (event.ctrlKey && !isMerging()) {
            selectingRectangle = true;
            selectingRectanglePoint = 1;
            selectingRectangleAdd = true;
            evalTextField.text = 'Выберите первую клетку';
            return;
        }

        if (_cellSize >= 30)
            return;

        var centerPoint:Point = new Point(currentWidth / 2, currentHeight / 2);
        centerPoint = localToGlobal(centerPoint);
        centerPoint = _field.globalToLocal(centerPoint);
        var lp:Point = screen2logical(centerPoint.x, centerPoint.y);

        _cellSize ++;

        redrawField();

        moveCellToCenter(lp.x, lp.y);
    }

    private function zoomOut_clickHandler(event:MouseEvent):void {
        if (event.ctrlKey) {
            selectingRectangle = true;
            selectingRectanglePoint = 1;
            selectingRectangleAdd = false;
            evalTextField.text = 'Выберите первую клетку';
            return;
        }

        if (_cellSize <= 10)
            return;

        //TODO here is a code duplication from zoomIn_clickHandler()
        var centerPoint:Point = new Point(currentWidth / 2, currentHeight / 2);
        centerPoint = localToGlobal(centerPoint);
        centerPoint = _field.globalToLocal(centerPoint);
        var lp:Point = screen2logical(centerPoint.x, centerPoint.y);

        _cellSize --;

        redrawField();

        moveCellToCenter(lp.x, lp.y);
    }

    private function evalButton_clickHandler(event:MouseEvent):void {
        evalTextField.text = 'Считаю...';

        //to update text field
        var t:Timer = new Timer(100, 1);
        t.addEventListener(TimerEvent.TIMER, function(event:Event):void {
            _area.evaluate();
            updateEvaluationInfo();
        });
        t.start();
    }

    private function updateEvaluationInfo():void {
        if (_area.wrongSizes) {
            evalTextField.text = '|w| = ' + _area.w_count + ' |b| = ' +
                    _area.b_count + ' 1:' + _area.sourceDisplay(0) + ' 2:' + _area.sourceDisplay(1);
            return;
        }

        if (! _area.evaluated)
            evalTextField.text = 'Не вычислено :(';
        else
            evalTextField.text = 'Вычислено!';
    }

    private function field_mouseMoveHandler(event:MouseEvent):void {
        if (startDragField || ! _showHints || ! _area.evaluated || ! _area.hasSource(0)) { //TODO hasSource(0?)
            tooltip.visible = false;
            return;
        }

        var pl:Point = screen2logical(event.localX, event.localY);
        var inv:Number = _area.couple(pl.x, pl.y);
        if (isNaN(inv)) {
            tooltip.visible = false;
            return;
        }

        var strTyp:String = _area.cellTypeString(pl.x, pl.y);

        var invText:String = inv.toFixed(10);
        while (/\.\d*0$/.test(invText))
            invText = invText.substring(0, invText.length - 1);

        tooltipText.text = strTyp + ": " + invText;
        tooltipText.y = 1;

        tooltip.x = event.localX - tooltip.width / 2;
        tooltip.y = event.localY - tooltip.height - 4;

        /*if (tooltip.x + tooltip.width > field.x + currentWidth)
            tooltip.x = field.x + currentWidth - tooltip.width;

        if (tooltip.x < field.x)
            tooltip.x = field.x;

        if (tooltip.y < field.y)
            tooltip.y = field.y;*/

        tooltip.visible = true;
    }

    private function field_rollOutHandler(event:MouseEvent):void {
        tooltip.visible = false;
    }

    public function get cellSize():int {
        return _cellSize;
    }

    public function set cellSize(value:int):void {
        _cellSize = value;
    }

    public function get field():Sprite {
        return _field;
    }

    //load and save

    public function load(data:Object, ind:int):void {
        cellSize = data['cellsize' + ind];
        field.x = data['fieldX' + ind];
        field.y = data['fieldY' + ind];

        _area.originX = data['originX' + ind];
        _area.originY = data['originY' + ind];
        for (var src:int = 0; src < 2; src++) {
            _area.setSourceX(src, data['sourceX' + ind + src]);
            _area.setSourceY(src, data['sourceY' + ind + src]);
            _area.setNoSource(src, !data['hasSource' + ind + src]);
        }
        _area.cells = data['cells' + ind];
    }
    
    public function save(data:Object, ind:int):void {
        data['cells' + ind] = _area.cells;
        data['originX' + ind] = _area.originX;
        data['originY' + ind] = _area.originY;

        for (var src:int = 0; src < 2; src++) {
            data['sourceX' + ind + src] = _area.getSourceX(src);
            data['sourceY' + ind + src] = _area.getSourceY(src);
            data['hasSource' + ind + src] = _area.hasSource(src);
        }

        data['cellsize' + ind] = cellSize;
        data['fieldX' + ind]= field.x;
        data['fieldY' + ind] = field.y;
    }
}
}
