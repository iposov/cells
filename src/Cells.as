package {

import flash.display.Sprite;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.NetStatusEvent;
import flash.net.SharedObject;

import model.Area;

import view.AreaView;

[SWF(width=1000, height=610)] //1366x768
public class Cells extends Sprite {

    private var areaView1:AreaView;
    private var areaView2:AreaView;
    private var areaView3:AreaView;
    private var areaView4:AreaView;

    private var loading:Boolean = false;

    public function Cells() {
        if (stage)
            init();
        else
            addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private static const LSO_NAME:String = "cells/mariasha";

    private function init(event:Event = null):void {
        removeEventListener(Event.ADDED_TO_STAGE, init);

        stage.scaleMode = StageScaleMode.NO_SCALE;

        var area1:Area = new Area();
        var area2:Area = new Area();
        var area3:Area = new Area();
        var area4:Area = new Area();

        areaView2 = new AreaView(area2, null, 'Поле 2', 494, 265, 2, 20, 994, 569);
        areaView2.x = 502;
        areaView2.y = 20;
        addChild(areaView2);

        areaView3 = new AreaView(area3, null, 'Поле 3', 494, 265, 2, 20, 994, 569);
        areaView3.x = 2;
        areaView3.y = 324;
        addChild(areaView3);

        areaView4 = new AreaView(area4, null, 'Поле 4', 494, 265, 2, 20, 994, 569);
        areaView4.x = 502;
        areaView4.y = 324;
        addChild(areaView4);

        areaView1 = new AreaView(area1, [areaView2, areaView3, areaView4], 'Поле 1', 494, 265, 2, 20, 994, 569);
        areaView1.uniformColoring = false;
        areaView1.x = 2;
        areaView1.y = 20;
        addChild(areaView1);

        areaView1.addEventListener(AreaView.MAXIMIZED, function (event:Event):void {
            areaView2.visible = !areaView1.maximized;
            areaView3.visible = !areaView1.maximized;
            areaView4.visible = !areaView1.maximized;
        });

        areaView2.addEventListener(AreaView.MAXIMIZED, function (event:Event):void {
            areaView1.visible = !areaView2.maximized;
            areaView3.visible = !areaView2.maximized;
            areaView4.visible = !areaView2.maximized;
        });

        areaView3.addEventListener(AreaView.MAXIMIZED, function (event:Event):void {
            areaView1.visible = !areaView3.maximized;
            areaView2.visible = !areaView3.maximized;
            areaView4.visible = !areaView3.maximized;
        });

        areaView4.addEventListener(AreaView.MAXIMIZED, function (event:Event):void {
            areaView1.visible = !areaView4.maximized;
            areaView2.visible = !areaView4.maximized;
            areaView3.visible = !areaView4.maximized;
        });

        area1.addEventListener(Event.CHANGE, save);
        area2.addEventListener(Event.CHANGE, save);
        area3.addEventListener(Event.CHANGE, save);
        area4.addEventListener(Event.CHANGE, save);
        area1.addEventListener(Area.SOURCE_CHANGE_EVENT, save);
        area2.addEventListener(Area.SOURCE_CHANGE_EVENT, save);
        area3.addEventListener(Area.SOURCE_CHANGE_EVENT, save);
        area4.addEventListener(Area.SOURCE_CHANGE_EVENT, save);

        SharedObject.getLocal(LSO_NAME).addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);

        load();
    }

    private function save(event:Event):void {
        if (loading)
            return;

        var src:int;

        var lso:SharedObject = SharedObject.getLocal(LSO_NAME);

        lso.data.saved = true;

        areaView1.save(lso.data, 1);
        areaView2.save(lso.data, 2);
        areaView3.save(lso.data, 3);
        areaView4.save(lso.data, 4);

        lso.flush();
    }

    private function load():void {
        loading = true;

        var src:int;

        var lso:SharedObject = SharedObject.getLocal(LSO_NAME);

        if (!lso.data.saved) {
            loading = false;
            return;
        }

        areaView1.load(lso.data, 1);
        areaView2.load(lso.data, 2);
        areaView3.load(lso.data, 3);
        areaView4.load(lso.data, 4);

        loading = false;
    }

    private function netStatusHandler(event:NetStatusEvent):void {
        //net status handled;
    }
}
}
