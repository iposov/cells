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

    private var area1:Area;
    private var area2:Area;
    private var area3:Area;
    private var area4:Area;

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

        area1 = new Area();
        area2 = new Area();
        area3 = new Area();
        area4 = new Area();

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

        var lso:SharedObject = SharedObject.getLocal(LSO_NAME);

        lso.data.saved = true;

        //1st area

        lso.data.cells1 = area1.cells;
        lso.data.originX1 = area1.originX;
        lso.data.originY1 = area1.originY;
        lso.data.sourceX1 = area1.sourceX;
        lso.data.sourceY1 = area1.sourceY;
        lso.data.hasSource1 = area1.hasSource();

        lso.data.cellsize1 = areaView1.cellSize;
        lso.data.fieldX1 = areaView1.field.x;
        lso.data.fieldY1 = areaView1.field.y;

        //2nd area

        lso.data.cells2 = area2.cells;
        lso.data.originX2 = area2.originX;
        lso.data.originY2 = area2.originY;
        lso.data.sourceX2 = area2.sourceX;
        lso.data.sourceY2 = area2.sourceY;
        lso.data.hasSource2 = area2.hasSource();

        lso.data.cellsize2 = areaView2.cellSize;
        lso.data.fieldX2 = areaView2.field.x;
        lso.data.fieldY2 = areaView2.field.y;

        //3rd area

        lso.data.cells3 = area3.cells;
        lso.data.originX3 = area3.originX;
        lso.data.originY3 = area3.originY;
        lso.data.sourceX3 = area3.sourceX;
        lso.data.sourceY3 = area3.sourceY;
        lso.data.hasSource3 = area3.hasSource();

        lso.data.cellsize3 = areaView3.cellSize;
        lso.data.fieldX3 = areaView3.field.x;
        lso.data.fieldY3 = areaView3.field.y;

        //4th area

        lso.data.cells4 = area4.cells;
        lso.data.originX4 = area4.originX;
        lso.data.originY4 = area4.originY;
        lso.data.sourceX4 = area4.sourceX;
        lso.data.sourceY4 = area4.sourceY;
        lso.data.hasSource4 = area4.hasSource();

        lso.data.cellsize4 = areaView4.cellSize;
        lso.data.fieldX4 = areaView4.field.x;
        lso.data.fieldY4 = areaView4.field.y;

        lso.flush();
    }

    private function load():void {
        loading = true;

        var lso:SharedObject = SharedObject.getLocal(LSO_NAME);

        if (!lso.data.saved) {
            loading = false;
            return;
        }

        //1st area

        areaView1.cellSize = lso.data.cellsize1;
        areaView1.field.x = lso.data.fieldX1;
        areaView1.field.y = lso.data.fieldY1;

        area1.originX = lso.data.originX1;
        area1.originY = lso.data.originY1;
        area1.sourceX = lso.data.sourceX1;
        area1.sourceY = lso.data.sourceY1;
        area1.noSource = !lso.data.hasSource1;
        area1.cells = lso.data.cells1;

        //2nd area

        areaView2.cellSize = lso.data.cellsize2;
        areaView2.field.x = lso.data.fieldX2;
        areaView2.field.y = lso.data.fieldY2;

        area2.originX = lso.data.originX2;
        area2.originY = lso.data.originY2;
        area2.sourceX = lso.data.sourceX2;
        area2.sourceY = lso.data.sourceY2;
        area2.noSource = !lso.data.hasSource2;
        area2.cells = lso.data.cells2;

        //3rd area

        if (! ('cellsize3' in lso.data)) { //old versions did not have such areas
            loading = false;
            return;
        }

        areaView3.cellSize = lso.data.cellsize3;
        areaView3.field.x = lso.data.fieldX3;
        areaView3.field.y = lso.data.fieldY3;

        area3.originX = lso.data.originX3;
        area3.originY = lso.data.originY3;
        area3.sourceX = lso.data.sourceX3;
        area3.sourceY = -lso.data.sourceY3;
        area3.noSource = !lso.data.hasSource3;
        area3.cells = lso.data.cells3;

        //4th area

        areaView4.cellSize = lso.data.cellsize4;
        areaView4.field.x = lso.data.fieldX4;
        areaView4.field.y = lso.data.fieldY4;

        area4.originX = lso.data.originX4;
        area4.originY = lso.data.originY4;
        area4.sourceX = lso.data.sourceX4;
        area4.sourceY = lso.data.sourceY4;
        area4.noSource = !lso.data.hasSource4;
        area4.cells = lso.data.cells4;

        loading = false;
    }

    private function netStatusHandler(event:NetStatusEvent):void {
        //net status handled;
    }
}
}
