/**
 * Created with IntelliJ IDEA.
 * User: ilya
 * Date: 08.08.13
 * Time: 21:52
 * To change this template use File | Settings | File Templates.
 */
package model {
public class Source {

    private var _sourceX:int = 0;
    private var _sourceY:int = 0;

    private var _noSource:Boolean = true;
    private var _sourceIsW:Boolean;
    private var _sourceInd:int;

    public function Source() {
    }


    public function get sourceX():int {
        return _sourceX;
    }

    public function set sourceX(value:int):void {
        _sourceX = value;
    }

    public function get sourceY():int {
        return _sourceY;
    }

    public function set sourceY(value:int):void {
        _sourceY = value;
    }

    public function get noSource():Boolean {
        return _noSource;
    }

    public function set noSource(value:Boolean):void {
        _noSource = value;
    }

    public function get sourceIsW():Boolean {
        return _sourceIsW;
    }

    public function set sourceIsW(value:Boolean):void {
        _sourceIsW = value;
    }

    public function get sourceInd():int {
        return _sourceInd;
    }

    public function set sourceInd(value:int):void {
        _sourceInd = value;
    }
}
}
