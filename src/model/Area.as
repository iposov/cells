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
    private var _differentSizes:Boolean = true;
    private var K:Array;
    private var K_1:Array;
    private var _det:Complex;
    private var w_cells:Array;
    private var b_cells:Array;
    private var _evaluated:Boolean = false;

    public function Area() {
        _cells = [];

//        for (var i:int = 0; i < 31; i++)
//            for (var j:int = 0; j < 31; j++)
//                _cells.push([i + 2, j - 20]);

        addEventListener(Event.CHANGE, evaluate, false, 1);
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
            updateSourceInfo(src);

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

    public function get differentSizes():Boolean {
        return _differentSizes;
    }

    public function get det():Complex {
        return _det;
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

        _differentSizes = w_cells.length != b_cells.length;
        if (_differentSizes) {
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

        var n:int = w_cells.length;

        if (n == 0)
            return;

        if (n > 100 && event != null) {
            _evaluated = false;
            return;
        }

        for (var src:int = 0; src < 2; src++)
            updateSourceInfo(src);

        K = new Array(n);
        for (var i:int = 0; i < n; i++) {
            xy = w_cells[i];
            typ = cellType(xy[0], xy[1]);
            K[i] = new Array(n);
            for (var j:int = 0; j < n; j++) {
                var xy2:Array = b_cells[j];
                var dx:int = xy2[0] - xy[0];
                var dy:int = xy2[1] - xy[1];

                if (dy == 0 && Math.abs(dx) == 1) //to the left or the the right
                    K[i][j] = new Complex(dx);
                else if (Math.abs(dy) == 1 && dx == 0) //up or down
                    K[i][j] = new Complex(0, dy);
                else
                    K[i][j] = new Complex(0);
            }
        }

        time = new Date().getTime();

        trace('before det eval: ' + n);

        evaluateInverseAndDeterminant();

        _evaluated = true;

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

    private function evaluateInverseAndDeterminant():void {
        var n:int = K.length;

        var K_0:Array = new Array(n);

        K_1 = new Array(n);
        for (var i:int = 0; i < n; i++) {
            K_0[i] = new Array(n);
            K_1[i] = new Array(n);
            for (var j:int = 0; j < n; j++) {
                K_0[i][j] = K[i][j].clone();
                K_1[i][j] = new Complex(i == j ? 1 : 0);
            }
        }

        logTime("K_1 and K_0 created");

        for (var t:int = 0; t < n; t++) {
            //from [t][t] down to [n-1][t] find the maximal module
            var bestInd:int = t;
            var bestModule:Number = K_0[t][t].norm2;
            for (i = t + 1; i < n; i++) {
                var module:Number = K_0[i][t].norm2;
                if (module > bestModule) {
                    bestModule = module;
                    bestInd = i;
                }
            }

            if (bestModule == 0) {
                _det = new Complex(0);
                return;
            }

            logTime('best module found');

            //swap lines if needed
            if (t != bestInd) {
                for (i = 0; i < n; i++) {
                    var tmp:Complex = K_0[t][i];
                    K_0[t][i] = K_0[bestInd][i];
                    K_0[bestInd][i] = tmp;

                    tmp = K_1[t][i];
                    K_1[t][i] = K_1[bestInd][i];
                    K_1[bestInd][i] = tmp;
                }
            }

            logTime('lines swapped');

            for (i = 0; i < n; i++) {
                if (i == t)
                    continue;

                var k:Complex = K_0[i][t].divide(K_0[t][t]);

                if (k.isZero())
                    continue;

                if (k._re != 0 && k._im != 0)
                    trace('k = ', k.toString());

                for (j = 0; j < n; j++) {
                    K_0[i][j].minusCoef0(K_0[t][j], k);
                    K_1[i][j].minusCoef0(K_1[t][j], k);
                }

//                K_1[i][0].minusCoef0(K_1[t][0], k); //only one column

                K_0[i][t].zero0(); //to increase accuracy
            }

            logTime("line " + t + " processed"); // 33.726 пропусков строчек
        }

        //evaluate determinant

        _det = new Complex(1);

        for (t = 0; t < n; t++) {
            var diag:Complex = K_0[t][t];
            for (j = 0; j < n; j++) {
                K_1[t][j].divide0(diag);
            }

            _det.mul0(diag);
        }

        //det = root of discriminant

        if (n % 2 == 1)
            _det.mul0(new Complex(0, 1));

        trace('det', det.toString());
    }

//    private function traceMatrix(K:Array, title:String):void {
//        trace("matrix", title);
//
//        for each (var line:Array in K)
//            trace(line);
//    }

    private function updateSourceInfo(src:int):void {
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

        _source[src].sourceInd = -1; //kann nicht sein
    }

    public function couple(x:Number, y:Number):Complex {
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

            if (pointIsW == _source[0].sourceIsW)
                return new Complex(0);

            return _source[0].sourceIsW ? K_1[ind][_source[0].sourceInd] : K_1[_source[0].sourceInd][ind];
        }

        return null;
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

}
}
