/**
 * Created with IntelliJ IDEA.
 * User: ilya
 * Date: 26.03.13
 * Time: 13:12
 */
package model {
import flash.events.Event;
import flash.events.EventDispatcher;

public class Area extends EventDispatcher {

    public static const SOURCE_CHANGE_EVENT:String = 'source change';

    private var _cells:Array; //array of pairs

    private var _originX:int = 0;
    private var _originY:int = 0;

    private var _source:Array = [new Source(), new Source()];

    //evaluation result
    private var _wrongSizes:Boolean = true;

    private var Kb_1:Array;
    private var Kw_1:Array;

    private var w_cells:Array;
    private var b_cells:Array;
    private var _evaluated:Boolean = false;
    private var _det_is_0:Array = [true, true];

    public function Area() {
        _cells = [];

//        for (var i:int = 0; i < 31; i++)
//            for (var j:int = 0; j < 31; j++)
//                _cells.push([i + 2, j - 20]);

        addEventListener(Event.CHANGE, evaluate, false, 1);
        addEventListener(Area.SOURCE_CHANGE_EVENT, evaluate, false, 1);
    }

    public function hasCell(x:int, y:int):Boolean {
        return getCellIndex(x, y) >= 0;
    }

    public function addCell(x:int, y:int):void {
        _cells.push([x, y]);

        dispatchEvent(new Event(Event.CHANGE));
    }

    public function removeCell(x:int, y:int):void {
        var ind:int = getCellIndex(x, y);
        if (ind >= 0)
            _cells.splice(ind, 1);

        for (var src:int = 0; src < 2; src ++)
            if (_source[src].sourceX == x && _source[src].sourceY == y)
                _source[src].noSource = true;

        dispatchEvent(new Event(Event.CHANGE));
    }

    public function getCellIndex(x:int, y:int):int {
        for (var i:int = 0; i < _cells.length; i++) {
            var xy:Array = _cells[i];
            if (xy[0] == x && xy[1] == y)
                return i;
        }

        return -1;
    }

    public function get cells():Array {
        return _cells;
    }

    public function setOrigin(x:int, y:int):void {
        _originX = x;
        _originY = y;

        dispatchEvent(new Event(Event.CHANGE));
    }

    public function setSource(src:int, x:int, y:int):void {
        if (! hasCell(x, y)) {
            _source[src].noSource = true;
            dispatchEvent(new Event(Event.CHANGE));
            return;
        }

        _source[src].sourceX = x;
        _source[src].sourceY = y;

        _source[src].noSource = false;

        if (_evaluated)
            updateSourceIndex(src);

        dispatchEvent(new Event(SOURCE_CHANGE_EVENT));
    }

    public function hasSource(src:int):Boolean {
        return !_source[src].noSource;
    }

    public function get originX():int {
        return _originX;
    }

    public function get originY():int {
        return _originY;
    }

    public function getSourceX(src:int):int {
        return _source[src].sourceX;
    }

    public function getSourceY(src:int):int {
        return _source[src].sourceY;
    }

    public function getSourceIsW(src:int):Boolean {
        return _source[src].sourceIsW;
    }

    public function getSourceInd(src:int):int {
        return _source[src].sourceInd;
    }

    public function cellType(x:int, y:int):int { //w0 = 0, w1 = 3, b0 = 2, b1 = 1
        x = Math.abs(x - _originX) % 2;
        y = Math.abs(y - _originY) % 2;

        return 2 * x + y;
    }

    public function cellTypeString(x:int, y:int):String {
        switch (cellType(x, y)) {
            case 0: return 'W0';
            case 1: return 'B1';
            case 2: return 'B0';
            case 3: return 'W1';
        }
        return '??';
    }

    public function clear():void {
        _cells = [];
        _source[0].noSource = true;
        _source[1].noSource = true;

        dispatchEvent(new Event(Event.CHANGE));
    }

    public function get wrongSizes():Boolean {
        return _wrongSizes;
    }

    public function get evaluated():Boolean {
        return _evaluated;
    }

    public function evaluate(event:Event = null):void {
        w_cells = [];
        b_cells = [];
        for each (var xy:Array in _cells) {
            var typ:int = cellType(xy[0], xy[1]);
            if (typ == 0 || typ == 3)
                w_cells.push(xy);
            else
                b_cells.push(xy);
        }

        var nw:int = w_count;
        var nb:int = b_count;

        _wrongSizes = nb - nw != 0 && nb - nw != 1;
        if (_wrongSizes || nb == 0 || nw == 0) {
            _wrongSizes = true;
            _evaluated = false;
            return;
        }

        for (var src:int = 0; src < 2; src++)
            updateSourceIndex(src);

        if (_source[0].noSource || _source[0].sourceIsW)
            _wrongSizes = true;
        if (_source[1].noSource)
            _wrongSizes = true;
        if (nb - nw == 1 && _source[1].sourceIsW)
            _wrongSizes = true;
        if (nb - nw == 0 && !_source[1].sourceIsW)
            _wrongSizes = true;

        if ((nw > 100 || nb > 100) && event != null) {
            _evaluated = false;
            return;
        }

        //sort w0 then w1 and b0 then b1

        function cmp_even_odd(a:Array, b:Array):int {
            var ta:int = cellType(a[0], a[1]);
            var tb:int = cellType(b[0], b[1]);
            return ta % 2 - tb % 2;
        }

        w_cells.sort(cmp_even_odd);
        b_cells.sort(cmp_even_odd);

        //create initial matrix K

        var eval_type:int = nb - nw;

        if (_wrongSizes) {
            _evaluated = false;
            return;
        }

        var Kb:Array = new Array(nb);
        var Bb:Array = new Array(nb);

        var s1x:int = _source[0].sourceX;
        var s1y:int = _source[0].sourceY;
        var s1i:int = _source[0].sourceInd;
        var s2x:int = _source[1].sourceX;
        var s2y:int = _source[1].sourceY;
        var s2i:int = _source[1].sourceInd;

        //add equation on black cells for every white cell
        for (var i:int = 0; i < nw; i++) {
            Kb[i] = new Array(nb);

            xy = w_cells[i];
            var x:int = xy[0];
            var y:int = xy[1];
            typ = cellType(x, y);

            Bb[i] = eval_type == 0 && s2i == i ? 1 : 0;

            for (var j:int = 0; j < nb; j++) {
                var xy_b:Array = b_cells[j];
                var dx:int = xy_b[0] - x;
                var dy:int = xy_b[1] - y;

                if (dx == 0 && Math.abs(dy) == 1) //to the top or to the bottom
                    Kb[i][j] = dy;
                else if (Math.abs(dx) == 1 && dy == 0) //to the left or to the right
                    Kb[i][j] = typ == 0 ? dx : -dx;
                else
                    Kb[i][j] = 0;
            }
        }

        //if there are more black cells than white, then add one more equation
        if (eval_type == 1) {
            Kb[nw] = new Array(nb);
            for (j = 0; j < nb; j++)
                Kb[nw][j] = j == s1i ? 1 : 0;
            Bb[nw] = 1;
        }

        //create white matrix

        var Kw:Array = new Array(nw);
        var Bw:Array = new Array(nw);

        //add equation on black cells for every white cell
        i = 0;
        for (var ii:int = 0; ii < nb; ii++) {
            if (eval_type == 1 && s2i == ii)
                continue;

            Kw[i] = new Array(nw);

            xy = b_cells[ii];
            x = xy[0];
            y = xy[1];
            typ = cellType(x, y);

            Bw[i] = s1i == ii ? 1 : 0;

            for (j = 0; j < nw; j++) {
                var xy_w:Array = w_cells[j];
                dx = xy_w[0] - x;
                dy = xy_w[1] - y;

                if (dx == 0 && Math.abs(dy) == 1) //to the top or to the bottom
                    Kw[i][j] = dy;
                else if (Math.abs(dx) == 1 && dy == 0) //to the left or to the right
                    Kw[i][j] = typ == 2 ? dx : -dx;
                else
                    Kw[i][j] = 0;
            }

            i += 1;
        }

        time = new Date().getTime();

        var ev_b:Array = evaluateInverseAndDeterminant(Kb, Bb);
        _det_is_0[0] = ev_b[0];
        Kb_1 = ev_b[1];

        var ev_w:Array = evaluateInverseAndDeterminant(Kw, Bw);
        _det_is_0[1] = ev_b[0];
        Kw_1 = ev_w[1];

        _evaluated = !_det_is_0[0] && !_det_is_0[1];

        logTime('after det eval');
    }

    private var time:Number;

    private function logTime(text:String):void {
        if (text != 'after det eval')
            return;

        var newTime:Number = new Date().getTime();
        var dt:Number = newTime - time;
        time = newTime;
        trace(text, dt / 1000.0);
    }

    //returns [det == 0, answer]
    private function evaluateInverseAndDeterminant(K:Array, B:Array):Array {
        var n:int = K.length;

        var K_0:Array = new Array(n);
        var K_1:Array = new Array(n);

        K_1 = new Array(n);
        for (var i:int = 0; i < n; i++) {
            K_0[i] = new Array(n);
            for (var j:int = 0; j < n; j++)
                K_0[i][j] = K[i][j];
            K_1[i] = B[i];
        }

        logTime("K_1 and K_0 created");

        for (var t:int = 0; t < n; t++) {
            //from [t][t] down to [n-1][t] find the maximal module
            var bestInd:int = t;
            var bestModule:Number = Math.abs(K_0[t][t]);
            for (i = t + 1; i < n; i++) {
                var module:Number = Math.abs(K_0[i][t]);
                if (module > bestModule) {
                    bestModule = module;
                    bestInd = i;
                }
            }

            if (bestModule == 0)
                return [true, null];

            logTime('best module found');

            //swap lines if needed
            if (t != bestInd) {
                for (i = 0; i < n; i++) {
                    var tmp:Number = K_0[t][i];
                    K_0[t][i] = K_0[bestInd][i];
                    K_0[bestInd][i] = tmp;
                }

                tmp = K_1[t];
                K_1[t] = K_1[bestInd];
                K_1[bestInd] = tmp;
            }

            logTime('lines swapped');

            for (i = 0; i < n; i++) {
                if (i == t)
                    continue;

                var k:Number = K_0[i][t] / K_0[t][t];

                if (k == 0)
                    continue;

                for (j = 0; j < n; j++)
                    K_0[i][j] = K_0[i][j] - k * K_0[t][j];
                K_1[i] = K_1[i] - k * K_1[t];

                K_0[i][t] = 0; //to increase accuracy
            }

            logTime("line " + t + " processed"); // 33.726 пропусков строчек
        }

        for (t = 0; t < n; t++)
            K_1[t] = K_1[t] / K_0[t][t];

        return [false, K_1];
    }

//    private function traceMatrix(K:Array, title:String):void {
//        trace("matrix", title);
//
//        for each (var line:Array in K)
//            trace(line);
//    }

    private function updateSourceIndex(src:int):void {
        if (_source[src].noSource)
            return;

        var typ:int = cellType(_source[src].sourceX, _source[src].sourceY);
        _source[src].sourceIsW = typ == 0 || typ == 3;
        var y_cells:Array = _source[src].sourceIsW ? w_cells : b_cells;

        for (var i:int = 0; i < y_cells.length; i++) {
            var cell:Array = y_cells[i];
            if (cell[0] == _source[src].sourceX && cell[1] == _source[src].sourceY) {
                _source[src].sourceInd = i;
                return;
            }
        }

        _source[src].sourceInd = -1;
    }

    public function couple(x:Number, y:Number):Number {
        for each (var y_cells:Array in [w_cells, b_cells]) {
            var ind:int = -1;
            for (var i:int = 0; i < y_cells.length; i++) {
                var cell:Array = y_cells[i];
                if (cell[0] == x && cell[1] == y) {
                    ind = i;
                    break;
                }
            }

            if (ind < 0)
                continue;

            var pointIsW:Boolean = y_cells == w_cells;

            return pointIsW ? Kw_1[ind] : Kb_1[ind];
        }

        return NaN;
    }

    public function addRectangle(x1:int, y1:int, x2:int, y2:int):void {
        if (x1 > x2) {
            var tmp:int = x1;
            x1 = x2;
            x2 = tmp;
        }

        if (y1 > y2) {
            tmp = y1;
            y1 = y2;
            y2 = tmp;
        }

        clearRectangle(x1, y1, x2, y2);

        for (var x:int = x1; x <= x2; x++)
            for (var y:int = y1; y <= y2; y++)
                _cells.push([x, y]);

        dispatchEvent(new Event(Event.CHANGE));
    }

    public function removeRectangle(x1:int, y1:int, x2:int, y2:int):void {
        if (x1 > x2) {
            var tmp:int = x1;
            x1 = x2;
            x2 = tmp;
        }

        if (y1 > y2) {
            tmp = y1;
            y1 = y2;
            y2 = tmp;
        }

        clearRectangle(x1, y1, x2, y2);

        for (var src:int = 0; src < 2; src++)
            if (hasSource(src) && x1 <= _source[src].sourceX && _source[src].sourceX <= x2 && y1 <= _source[src].sourceY && _source[src].sourceY <= y2)
                _source[src].noSource = true;

        dispatchEvent(new Event(Event.CHANGE));
    }

    private function clearRectangle(x1:int, y1:int, x2:int, y2:int):void {
        var c:Array = [];

        for each (var cell:Array in _cells)
            if (x1 > cell[0] || cell[0] > x2 || y1 > cell[1] || cell[1] > y2)
                c.push(cell);

        _cells = c;
    }

    public function set cells(value:Array):void {
        _cells = value;
        dispatchEvent(new Event(Event.CHANGE));
    }


    public function set originX(value:int):void {
        _originX = value;
    }

    public function set originY(value:int):void {
        _originY = value;
    }

    public function setSourceX(src:int, value:int):void {
        _source[src].sourceX = value;
    }

    public function setSourceY(src:int, value:int):void {
        _source[src].sourceY = value;
    }

    public function setNoSource(src:int, value:Boolean):void {
        _source[src].noSource = value;
    }

    public function get w_count():int {
        return w_cells.length;
    }

    public function get b_count():int {
        return b_cells.length;
    }

    public function det_is_0(src:int):Boolean {
        return _det_is_0[src];
    }

    public function sourceDisplay(src:int):String {
        return _source[src].display;
    }
}
}
