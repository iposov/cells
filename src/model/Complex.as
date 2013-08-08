/**
 * Created with IntelliJ IDEA.
 * User: ilya
 * Date: 26.03.13
 * Time: 21:10
 */
package model {
public class Complex {
    internal var _re:Number;
    internal var _im:Number;

    public function Complex(re:Number, im:Number = 0) {
        _re = re;
        _im = im;
    }

    public function get norm2():Number {
        return _re * _re + _im * _im;
    }

    public function get norm():Number {
        return Math.sqrt(norm2);
    }

    public function clone():Complex {
        return new Complex(_re, _im);
    }

    public function divide(c:Complex):Complex {
        return clone().divide0(c);
    }

    public function divide0(c:Complex):Complex {
        var r:Number = _re * c._re + _im * c._im;
        var i:Number = - _re * c._im + _im * c._re;

        var n:Number = c.norm2;
        _re = r / n;
        _im = i / n;

        return this;
    }

    public function minus(c:Complex):Complex {
        return clone().minus0(c);
    }

    public function minus0(c:Complex):Complex {
        _re -= c._re;
        _im -= c._im;

        return this;
    }

    public function plus(c:Complex):Complex {
        return clone().plus0(c);
    }

    public function plus0(c:Complex):Complex {
        _re += c._re;
        _im += c._im;

        return this;
    }

    public function mul(c:Complex):Complex {
        return clone().mul0(c);
    }

    public function mul0(c:Complex):Complex {
        var r:Number = _re * c._re - _im * c._im;
        var i:Number = _re * c._im + _im * c._re;

        _re = r;
        _im = i;

        return this;
    }

    public function toString():String {
        var res:String = '';

        if (_re != 0)
            res += _re.toPrecision(6);

        if (_im < 0)
            res += ' - ';
        else if (_im > 0) {
            if (_re != 0)
                res += ' + ';
        }

        if (_im < 0 || _im > 0)
            res += Math.abs(_im).toPrecision(6) + " * i";

        if (res == '')
            res = '0';

        return res;
    }

    public function isZero():Boolean {
        return _re == 0 && _im == 0;
    }

    public function minusCoef0(c:Complex, k:Complex):void {
        _re -= c._re * k._re - c._im * k._im;
        _im -= c._im * k._re + c._re * k._im;
    }

    public function zero0():void {
        _re = 0;
        _im = 0;
    }
}
}
