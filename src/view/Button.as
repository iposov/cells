/**
 * Created with IntelliJ IDEA.
 * User: ilya
 * Date: 26.03.13
 * Time: 18:36
 */
package view {
import flash.display.Graphics;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

public class Button extends SimpleButton {

    private static const DEFAULT_WIDTH:int = 100;
    private static const DEFAULT_HEIGHT:int = 30;

    public function Button(title:String, width:int = DEFAULT_WIDTH, height:int = DEFAULT_HEIGHT) {

        var mainSprite:* = createSprite(width, height, 0xFFFF00, title);
        super(
                mainSprite,
                createSprite(width, height, 0xFFFF88, title),
                createSprite(width, height, 0xFFFF88, title, 1, 1),
                mainSprite
        );
    }

    public static function createSprite(width:int, height:int, color:uint, text:String = '', dx:int = 0, dy:int = 0):Sprite {
        var s:Sprite = new Sprite();

        var g:Graphics = s.graphics;

        g.lineStyle(2, 0x000000);
        g.beginFill(color);
        g.drawRect(0, 0, width, height);
        g.endFill();

        var tf:TextField = new TextField();

        tf.defaultTextFormat = new TextFormat('Arial', 14);
        tf.autoSize = TextFieldAutoSize.CENTER;
        tf.x = width / 2;
        tf.text = text;
        tf.y = (height - tf.textHeight) / 2;
        tf.selectable = false;

        tf.x += dx;
        tf.y += dy;

        s.addChild(tf);

        return s;
    }
}
}
