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
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.utils.Timer;

import model.Area;
import model.Complex;

public class AreaView extends Sprite {

    public static const MAXIMIZED:String = 'event maximized';
    public static const MERGE_CLICK:String = 'event merge';

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
    private var coefTextField:TextField;
    private var tooltip:Sprite;
    private var tooltipText:TextField;
    private var mergeButton:Sprite;

    private var selectingRectangle:Boolean = false;
    private var selectingRectangleAdd:Boolean;
    private var selectingRectanglePoint:int = 0;
    private var selectingRectangle1stPoint:Point; //TODO report 'convert to local'

    private var _mergers:Array = [];
    private var mainMerge:Boolean = true;
    private var _mergeOn:Boolean = false;

    private var _uniformColoring:Boolean = true;

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

        if (mergers != null)
            for each (var mergerArea:AreaView in mergers)
                mergerArea.addEventListener(MERGE_CLICK, mergeRegimeChangeHandler);
        else
            mainMerge = false;

        initView(normalWidth, normalHeight);

        redrawField();
    }

    private function isMerging():Boolean {
        return _mergers != null && _mergers.length > 0;
    }

    private function mergeRegimeChangeHandler(event:Event):void {
        var merger:AreaView = AreaView(event.target);
        if (merger.mergeOn) {
            if (!_area.evaluated || !_area.hasSource()) {
                merger.mergeOn = false;
                coefTextField.type = isMerging() ? TextFieldType.DYNAMIC : TextFieldType.INPUT;
                return;
            }

            _mergers.push(merger);
        } else {
            var ind:int = _mergers.indexOf(merger);
            if (ind >= 0)
                _mergers.splice(ind, 1);
        }

        redrawField();
        initTooltip();
        coefTextField.type = isMerging() ? TextFieldType.DYNAMIC : TextFieldType.INPUT;
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

        //merge
        if (! mainMerge) {
            mergeButton = Button.createSprite(80, 14, 0xFF8888, 'merge +', 0, -3);
            mergeButton.addEventListener(MouseEvent.CLICK, mergeButton_clickHandler);
            mergeButton.x = width - 106;
            mergeButton.y = -16;
            addChild(mergeButton);
        }

        //init coefTextField
        coefTextField = new TextField();
        coefTextField.border = true;
        coefTextField.borderColor = 0x000000;
        coefTextField.type = TextFieldType.INPUT;
        coefTextField.defaultTextFormat = new TextFormat('Arial', 12, 0, true, null, null, null, null, TextFormatAlign.CENTER);
        coefTextField.width = 40;
        coefTextField.height = 16;
        coefTextField.x = width - 106 - coefTextField.width - 6;
        coefTextField.y = -18;
        coefTextField.text = '1';
        addChild(coefTextField);

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
        updateEvaluatioInfo();

        if (!mainMerge)
            mergeOn = false;
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

        if (isMerging())
            drawMergerCells();
        else
            drawCells();

        //mark source
        if (_area.hasSource()) {
            var p:Point = logical2screen(_area.sourceX, _area.sourceY);
            g.lineStyle(2, 0xFF0000);
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

    private function linComb(x:int, y:int):Complex {
        var c:Complex = _area.couple(x, y);
        if (c == null)
            return null;
        
        var lc:Complex = coefficient.mul(c);

        for each (var areaView:AreaView in _mergers) {
            var sx:int = areaView.area.sourceX;
            var sy:int = areaView.area.sourceY;

            c = areaView.area.couple(x + sx - _area.sourceX, y + sy - _area.sourceY);
            if (c == null)
                return null;

            var coef:Complex = areaView.coefficient;

            lc.plus0(coef.mul0(c));
        }

        return lc;
    }

    private function drawMergerCells():void {
        var g:Graphics = _field.graphics;

        g.lineStyle();

        //create draw list

        var drawList:Array = [];
        var norms:Array = [];
        var maxNorm:Number = 0;

        for each (var xy:Array in _area.cells) {
            var lc:Complex = linComb(xy[0], xy[1]);

            if (lc == null)
                continue;

            var norm:Number = lc.norm;
            if (norm > maxNorm)
                maxNorm = norm;
            drawList.push([xy[0], xy[1], norm]);
            norms.push(norm);
        }

        norms.sort(Array.NUMERIC);

        for each (var item:Array in drawList) {
            norm = item[2];

            if (_uniformColoring)
                var t:int = Math.round(norm * 255 / maxNorm);
            else
                t = norms.indexOf(norm) * 255 / norms.length;

            var c:uint = t << 16 | 0xFF - t;

            var p:Point = logical2screen(item[0], item[1]);

            g.beginFill(c);
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
                else
                    _area.setSource(p.x, p.y);
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
            updateEvaluatioInfo();
        });
        t.start();
    }

    private function updateEvaluatioInfo():void {
        if (_area.differentSizes) {
            evalTextField.text = 'w_0 + w_1 <> b_0 + b_1';
            return;
        }

        if (! _area.evaluated) {
            evalTextField.text = 'не вычислено';
            return;
        }

        evalTextField.text = 'det = ' + _area.det.toString();
    }

    private function field_mouseMoveHandler(event:MouseEvent):void {
        if (startDragField || ! _showHints || ! _area.evaluated || ! _area.hasSource()) {
            tooltip.visible = false;
            return;
        }

        var pl:Point = screen2logical(event.localX, event.localY);
        var inv:Complex = _area.couple(pl.x, pl.y);
        if (inv == null) {
            tooltip.visible = false;
            return;
        }

        var strTyp:String = _area.cellTypeString(pl.x, pl.y);

        if (isMerging()) {
            var lc:Complex = linComb(pl.x, pl.y);

            if (lc == null) {
                tooltip.visible = false;
                return;
            }

            var text:String = "lc: " + lc.toString();
        } else
            text = strTyp + ": " + inv.toString();

        tooltipText.text = text;
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

    private function mergeButton_clickHandler(event:MouseEvent):void {
        mergeOn = !mergeOn;
    }

    public function get mergeOn():Boolean {
        return _mergeOn;
    }

    public function set mergeOn(value:Boolean):void {
        if (_mergeOn == value)
            return;

        if (value)
            if (!_area.hasSource() || !_area.evaluated)
                return;

        _mergeOn = value;

        if (_mergeOn)
            TextField(mergeButton.getChildAt(0)).text = 'merge -';
        else
            TextField(mergeButton.getChildAt(0)).text = 'merge +';

        coefTextField.type = _mergeOn ? TextFieldType.DYNAMIC : TextFieldType.INPUT;

        dispatchEvent(new Event(MERGE_CLICK));
    }

    public function set uniformColoring(value:Boolean):void {
        _uniformColoring = value;
    }

    public function get coefficient():Complex {
        var txt:String = coefTextField.text.replace(/ /, '');
        if (txt.length == 0)
            return new Complex(0);
        if (txt.charAt(txt.length - 1) == 'i') {
            var imaginary:Boolean = true;
            txt = txt.substring(0, txt.length - 1);
        } else
            imaginary = false;

        if (imaginary)
            return new Complex(0, Number(txt));
        else
            return new Complex(Number(txt));
    }
}
}
