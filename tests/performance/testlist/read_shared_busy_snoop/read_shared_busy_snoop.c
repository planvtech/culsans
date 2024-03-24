// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "read_shared_busy_snoop.h"
#include <stdint.h>
#include "encoding.h"

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
// cache is 32kB: 16B cachelines x 256 entries x 8 ways
volatile uint128_t data[256*8] __attribute__((section(".cache_share_region")));

volatile uint128_t dummy __attribute__((section(".nocache_share_region")));
volatile uint128_t* dummyptr;

void unrolled_read();

void prepare()
{
  for (int i = 0; i < sizeof(data)/sizeof(data[0]); i++)
    data[i] = i+1;

  dummy = 0;
}

int read_shared_busy_snoop(int cid, int nc)
{
  long begin, end;

  if (cid == 0) {
    begin = rdcycle();
    unrolled_read();
    end = rdcycle();
    exit((end-begin)>>11);
  }

  // create some traffic
  dummyptr = &dummy;
  while (1) {
    *(dummyptr++);
  }

  return 0;
}

void unrolled_read()
{
volatile uint64_t* dataptr = (uint64_t*)data;
*(dataptr+2*0);
*(dataptr+2*1);
*(dataptr+2*2);
*(dataptr+2*3);
*(dataptr+2*4);
*(dataptr+2*5);
*(dataptr+2*6);
*(dataptr+2*7);
*(dataptr+2*8);
*(dataptr+2*9);
*(dataptr+2*10);
*(dataptr+2*11);
*(dataptr+2*12);
*(dataptr+2*13);
*(dataptr+2*14);
*(dataptr+2*15);
*(dataptr+2*16);
*(dataptr+2*17);
*(dataptr+2*18);
*(dataptr+2*19);
*(dataptr+2*20);
*(dataptr+2*21);
*(dataptr+2*22);
*(dataptr+2*23);
*(dataptr+2*24);
*(dataptr+2*25);
*(dataptr+2*26);
*(dataptr+2*27);
*(dataptr+2*28);
*(dataptr+2*29);
*(dataptr+2*30);
*(dataptr+2*31);
*(dataptr+2*32);
*(dataptr+2*33);
*(dataptr+2*34);
*(dataptr+2*35);
*(dataptr+2*36);
*(dataptr+2*37);
*(dataptr+2*38);
*(dataptr+2*39);
*(dataptr+2*40);
*(dataptr+2*41);
*(dataptr+2*42);
*(dataptr+2*43);
*(dataptr+2*44);
*(dataptr+2*45);
*(dataptr+2*46);
*(dataptr+2*47);
*(dataptr+2*48);
*(dataptr+2*49);
*(dataptr+2*50);
*(dataptr+2*51);
*(dataptr+2*52);
*(dataptr+2*53);
*(dataptr+2*54);
*(dataptr+2*55);
*(dataptr+2*56);
*(dataptr+2*57);
*(dataptr+2*58);
*(dataptr+2*59);
*(dataptr+2*60);
*(dataptr+2*61);
*(dataptr+2*62);
*(dataptr+2*63);
*(dataptr+2*64);
*(dataptr+2*65);
*(dataptr+2*66);
*(dataptr+2*67);
*(dataptr+2*68);
*(dataptr+2*69);
*(dataptr+2*70);
*(dataptr+2*71);
*(dataptr+2*72);
*(dataptr+2*73);
*(dataptr+2*74);
*(dataptr+2*75);
*(dataptr+2*76);
*(dataptr+2*77);
*(dataptr+2*78);
*(dataptr+2*79);
*(dataptr+2*80);
*(dataptr+2*81);
*(dataptr+2*82);
*(dataptr+2*83);
*(dataptr+2*84);
*(dataptr+2*85);
*(dataptr+2*86);
*(dataptr+2*87);
*(dataptr+2*88);
*(dataptr+2*89);
*(dataptr+2*90);
*(dataptr+2*91);
*(dataptr+2*92);
*(dataptr+2*93);
*(dataptr+2*94);
*(dataptr+2*95);
*(dataptr+2*96);
*(dataptr+2*97);
*(dataptr+2*98);
*(dataptr+2*99);
*(dataptr+2*100);
*(dataptr+2*101);
*(dataptr+2*102);
*(dataptr+2*103);
*(dataptr+2*104);
*(dataptr+2*105);
*(dataptr+2*106);
*(dataptr+2*107);
*(dataptr+2*108);
*(dataptr+2*109);
*(dataptr+2*110);
*(dataptr+2*111);
*(dataptr+2*112);
*(dataptr+2*113);
*(dataptr+2*114);
*(dataptr+2*115);
*(dataptr+2*116);
*(dataptr+2*117);
*(dataptr+2*118);
*(dataptr+2*119);
*(dataptr+2*120);
*(dataptr+2*121);
*(dataptr+2*122);
*(dataptr+2*123);
*(dataptr+2*124);
*(dataptr+2*125);
*(dataptr+2*126);
*(dataptr+2*127);
*(dataptr+2*128);
*(dataptr+2*129);
*(dataptr+2*130);
*(dataptr+2*131);
*(dataptr+2*132);
*(dataptr+2*133);
*(dataptr+2*134);
*(dataptr+2*135);
*(dataptr+2*136);
*(dataptr+2*137);
*(dataptr+2*138);
*(dataptr+2*139);
*(dataptr+2*140);
*(dataptr+2*141);
*(dataptr+2*142);
*(dataptr+2*143);
*(dataptr+2*144);
*(dataptr+2*145);
*(dataptr+2*146);
*(dataptr+2*147);
*(dataptr+2*148);
*(dataptr+2*149);
*(dataptr+2*150);
*(dataptr+2*151);
*(dataptr+2*152);
*(dataptr+2*153);
*(dataptr+2*154);
*(dataptr+2*155);
*(dataptr+2*156);
*(dataptr+2*157);
*(dataptr+2*158);
*(dataptr+2*159);
*(dataptr+2*160);
*(dataptr+2*161);
*(dataptr+2*162);
*(dataptr+2*163);
*(dataptr+2*164);
*(dataptr+2*165);
*(dataptr+2*166);
*(dataptr+2*167);
*(dataptr+2*168);
*(dataptr+2*169);
*(dataptr+2*170);
*(dataptr+2*171);
*(dataptr+2*172);
*(dataptr+2*173);
*(dataptr+2*174);
*(dataptr+2*175);
*(dataptr+2*176);
*(dataptr+2*177);
*(dataptr+2*178);
*(dataptr+2*179);
*(dataptr+2*180);
*(dataptr+2*181);
*(dataptr+2*182);
*(dataptr+2*183);
*(dataptr+2*184);
*(dataptr+2*185);
*(dataptr+2*186);
*(dataptr+2*187);
*(dataptr+2*188);
*(dataptr+2*189);
*(dataptr+2*190);
*(dataptr+2*191);
*(dataptr+2*192);
*(dataptr+2*193);
*(dataptr+2*194);
*(dataptr+2*195);
*(dataptr+2*196);
*(dataptr+2*197);
*(dataptr+2*198);
*(dataptr+2*199);
*(dataptr+2*200);
*(dataptr+2*201);
*(dataptr+2*202);
*(dataptr+2*203);
*(dataptr+2*204);
*(dataptr+2*205);
*(dataptr+2*206);
*(dataptr+2*207);
*(dataptr+2*208);
*(dataptr+2*209);
*(dataptr+2*210);
*(dataptr+2*211);
*(dataptr+2*212);
*(dataptr+2*213);
*(dataptr+2*214);
*(dataptr+2*215);
*(dataptr+2*216);
*(dataptr+2*217);
*(dataptr+2*218);
*(dataptr+2*219);
*(dataptr+2*220);
*(dataptr+2*221);
*(dataptr+2*222);
*(dataptr+2*223);
*(dataptr+2*224);
*(dataptr+2*225);
*(dataptr+2*226);
*(dataptr+2*227);
*(dataptr+2*228);
*(dataptr+2*229);
*(dataptr+2*230);
*(dataptr+2*231);
*(dataptr+2*232);
*(dataptr+2*233);
*(dataptr+2*234);
*(dataptr+2*235);
*(dataptr+2*236);
*(dataptr+2*237);
*(dataptr+2*238);
*(dataptr+2*239);
*(dataptr+2*240);
*(dataptr+2*241);
*(dataptr+2*242);
*(dataptr+2*243);
*(dataptr+2*244);
*(dataptr+2*245);
*(dataptr+2*246);
*(dataptr+2*247);
*(dataptr+2*248);
*(dataptr+2*249);
*(dataptr+2*250);
*(dataptr+2*251);
*(dataptr+2*252);
*(dataptr+2*253);
*(dataptr+2*254);
*(dataptr+2*255);
*(dataptr+2*256);
*(dataptr+2*257);
*(dataptr+2*258);
*(dataptr+2*259);
*(dataptr+2*260);
*(dataptr+2*261);
*(dataptr+2*262);
*(dataptr+2*263);
*(dataptr+2*264);
*(dataptr+2*265);
*(dataptr+2*266);
*(dataptr+2*267);
*(dataptr+2*268);
*(dataptr+2*269);
*(dataptr+2*270);
*(dataptr+2*271);
*(dataptr+2*272);
*(dataptr+2*273);
*(dataptr+2*274);
*(dataptr+2*275);
*(dataptr+2*276);
*(dataptr+2*277);
*(dataptr+2*278);
*(dataptr+2*279);
*(dataptr+2*280);
*(dataptr+2*281);
*(dataptr+2*282);
*(dataptr+2*283);
*(dataptr+2*284);
*(dataptr+2*285);
*(dataptr+2*286);
*(dataptr+2*287);
*(dataptr+2*288);
*(dataptr+2*289);
*(dataptr+2*290);
*(dataptr+2*291);
*(dataptr+2*292);
*(dataptr+2*293);
*(dataptr+2*294);
*(dataptr+2*295);
*(dataptr+2*296);
*(dataptr+2*297);
*(dataptr+2*298);
*(dataptr+2*299);
*(dataptr+2*300);
*(dataptr+2*301);
*(dataptr+2*302);
*(dataptr+2*303);
*(dataptr+2*304);
*(dataptr+2*305);
*(dataptr+2*306);
*(dataptr+2*307);
*(dataptr+2*308);
*(dataptr+2*309);
*(dataptr+2*310);
*(dataptr+2*311);
*(dataptr+2*312);
*(dataptr+2*313);
*(dataptr+2*314);
*(dataptr+2*315);
*(dataptr+2*316);
*(dataptr+2*317);
*(dataptr+2*318);
*(dataptr+2*319);
*(dataptr+2*320);
*(dataptr+2*321);
*(dataptr+2*322);
*(dataptr+2*323);
*(dataptr+2*324);
*(dataptr+2*325);
*(dataptr+2*326);
*(dataptr+2*327);
*(dataptr+2*328);
*(dataptr+2*329);
*(dataptr+2*330);
*(dataptr+2*331);
*(dataptr+2*332);
*(dataptr+2*333);
*(dataptr+2*334);
*(dataptr+2*335);
*(dataptr+2*336);
*(dataptr+2*337);
*(dataptr+2*338);
*(dataptr+2*339);
*(dataptr+2*340);
*(dataptr+2*341);
*(dataptr+2*342);
*(dataptr+2*343);
*(dataptr+2*344);
*(dataptr+2*345);
*(dataptr+2*346);
*(dataptr+2*347);
*(dataptr+2*348);
*(dataptr+2*349);
*(dataptr+2*350);
*(dataptr+2*351);
*(dataptr+2*352);
*(dataptr+2*353);
*(dataptr+2*354);
*(dataptr+2*355);
*(dataptr+2*356);
*(dataptr+2*357);
*(dataptr+2*358);
*(dataptr+2*359);
*(dataptr+2*360);
*(dataptr+2*361);
*(dataptr+2*362);
*(dataptr+2*363);
*(dataptr+2*364);
*(dataptr+2*365);
*(dataptr+2*366);
*(dataptr+2*367);
*(dataptr+2*368);
*(dataptr+2*369);
*(dataptr+2*370);
*(dataptr+2*371);
*(dataptr+2*372);
*(dataptr+2*373);
*(dataptr+2*374);
*(dataptr+2*375);
*(dataptr+2*376);
*(dataptr+2*377);
*(dataptr+2*378);
*(dataptr+2*379);
*(dataptr+2*380);
*(dataptr+2*381);
*(dataptr+2*382);
*(dataptr+2*383);
*(dataptr+2*384);
*(dataptr+2*385);
*(dataptr+2*386);
*(dataptr+2*387);
*(dataptr+2*388);
*(dataptr+2*389);
*(dataptr+2*390);
*(dataptr+2*391);
*(dataptr+2*392);
*(dataptr+2*393);
*(dataptr+2*394);
*(dataptr+2*395);
*(dataptr+2*396);
*(dataptr+2*397);
*(dataptr+2*398);
*(dataptr+2*399);
*(dataptr+2*400);
*(dataptr+2*401);
*(dataptr+2*402);
*(dataptr+2*403);
*(dataptr+2*404);
*(dataptr+2*405);
*(dataptr+2*406);
*(dataptr+2*407);
*(dataptr+2*408);
*(dataptr+2*409);
*(dataptr+2*410);
*(dataptr+2*411);
*(dataptr+2*412);
*(dataptr+2*413);
*(dataptr+2*414);
*(dataptr+2*415);
*(dataptr+2*416);
*(dataptr+2*417);
*(dataptr+2*418);
*(dataptr+2*419);
*(dataptr+2*420);
*(dataptr+2*421);
*(dataptr+2*422);
*(dataptr+2*423);
*(dataptr+2*424);
*(dataptr+2*425);
*(dataptr+2*426);
*(dataptr+2*427);
*(dataptr+2*428);
*(dataptr+2*429);
*(dataptr+2*430);
*(dataptr+2*431);
*(dataptr+2*432);
*(dataptr+2*433);
*(dataptr+2*434);
*(dataptr+2*435);
*(dataptr+2*436);
*(dataptr+2*437);
*(dataptr+2*438);
*(dataptr+2*439);
*(dataptr+2*440);
*(dataptr+2*441);
*(dataptr+2*442);
*(dataptr+2*443);
*(dataptr+2*444);
*(dataptr+2*445);
*(dataptr+2*446);
*(dataptr+2*447);
*(dataptr+2*448);
*(dataptr+2*449);
*(dataptr+2*450);
*(dataptr+2*451);
*(dataptr+2*452);
*(dataptr+2*453);
*(dataptr+2*454);
*(dataptr+2*455);
*(dataptr+2*456);
*(dataptr+2*457);
*(dataptr+2*458);
*(dataptr+2*459);
*(dataptr+2*460);
*(dataptr+2*461);
*(dataptr+2*462);
*(dataptr+2*463);
*(dataptr+2*464);
*(dataptr+2*465);
*(dataptr+2*466);
*(dataptr+2*467);
*(dataptr+2*468);
*(dataptr+2*469);
*(dataptr+2*470);
*(dataptr+2*471);
*(dataptr+2*472);
*(dataptr+2*473);
*(dataptr+2*474);
*(dataptr+2*475);
*(dataptr+2*476);
*(dataptr+2*477);
*(dataptr+2*478);
*(dataptr+2*479);
*(dataptr+2*480);
*(dataptr+2*481);
*(dataptr+2*482);
*(dataptr+2*483);
*(dataptr+2*484);
*(dataptr+2*485);
*(dataptr+2*486);
*(dataptr+2*487);
*(dataptr+2*488);
*(dataptr+2*489);
*(dataptr+2*490);
*(dataptr+2*491);
*(dataptr+2*492);
*(dataptr+2*493);
*(dataptr+2*494);
*(dataptr+2*495);
*(dataptr+2*496);
*(dataptr+2*497);
*(dataptr+2*498);
*(dataptr+2*499);
*(dataptr+2*500);
*(dataptr+2*501);
*(dataptr+2*502);
*(dataptr+2*503);
*(dataptr+2*504);
*(dataptr+2*505);
*(dataptr+2*506);
*(dataptr+2*507);
*(dataptr+2*508);
*(dataptr+2*509);
*(dataptr+2*510);
*(dataptr+2*511);
*(dataptr+2*512);
*(dataptr+2*513);
*(dataptr+2*514);
*(dataptr+2*515);
*(dataptr+2*516);
*(dataptr+2*517);
*(dataptr+2*518);
*(dataptr+2*519);
*(dataptr+2*520);
*(dataptr+2*521);
*(dataptr+2*522);
*(dataptr+2*523);
*(dataptr+2*524);
*(dataptr+2*525);
*(dataptr+2*526);
*(dataptr+2*527);
*(dataptr+2*528);
*(dataptr+2*529);
*(dataptr+2*530);
*(dataptr+2*531);
*(dataptr+2*532);
*(dataptr+2*533);
*(dataptr+2*534);
*(dataptr+2*535);
*(dataptr+2*536);
*(dataptr+2*537);
*(dataptr+2*538);
*(dataptr+2*539);
*(dataptr+2*540);
*(dataptr+2*541);
*(dataptr+2*542);
*(dataptr+2*543);
*(dataptr+2*544);
*(dataptr+2*545);
*(dataptr+2*546);
*(dataptr+2*547);
*(dataptr+2*548);
*(dataptr+2*549);
*(dataptr+2*550);
*(dataptr+2*551);
*(dataptr+2*552);
*(dataptr+2*553);
*(dataptr+2*554);
*(dataptr+2*555);
*(dataptr+2*556);
*(dataptr+2*557);
*(dataptr+2*558);
*(dataptr+2*559);
*(dataptr+2*560);
*(dataptr+2*561);
*(dataptr+2*562);
*(dataptr+2*563);
*(dataptr+2*564);
*(dataptr+2*565);
*(dataptr+2*566);
*(dataptr+2*567);
*(dataptr+2*568);
*(dataptr+2*569);
*(dataptr+2*570);
*(dataptr+2*571);
*(dataptr+2*572);
*(dataptr+2*573);
*(dataptr+2*574);
*(dataptr+2*575);
*(dataptr+2*576);
*(dataptr+2*577);
*(dataptr+2*578);
*(dataptr+2*579);
*(dataptr+2*580);
*(dataptr+2*581);
*(dataptr+2*582);
*(dataptr+2*583);
*(dataptr+2*584);
*(dataptr+2*585);
*(dataptr+2*586);
*(dataptr+2*587);
*(dataptr+2*588);
*(dataptr+2*589);
*(dataptr+2*590);
*(dataptr+2*591);
*(dataptr+2*592);
*(dataptr+2*593);
*(dataptr+2*594);
*(dataptr+2*595);
*(dataptr+2*596);
*(dataptr+2*597);
*(dataptr+2*598);
*(dataptr+2*599);
*(dataptr+2*600);
*(dataptr+2*601);
*(dataptr+2*602);
*(dataptr+2*603);
*(dataptr+2*604);
*(dataptr+2*605);
*(dataptr+2*606);
*(dataptr+2*607);
*(dataptr+2*608);
*(dataptr+2*609);
*(dataptr+2*610);
*(dataptr+2*611);
*(dataptr+2*612);
*(dataptr+2*613);
*(dataptr+2*614);
*(dataptr+2*615);
*(dataptr+2*616);
*(dataptr+2*617);
*(dataptr+2*618);
*(dataptr+2*619);
*(dataptr+2*620);
*(dataptr+2*621);
*(dataptr+2*622);
*(dataptr+2*623);
*(dataptr+2*624);
*(dataptr+2*625);
*(dataptr+2*626);
*(dataptr+2*627);
*(dataptr+2*628);
*(dataptr+2*629);
*(dataptr+2*630);
*(dataptr+2*631);
*(dataptr+2*632);
*(dataptr+2*633);
*(dataptr+2*634);
*(dataptr+2*635);
*(dataptr+2*636);
*(dataptr+2*637);
*(dataptr+2*638);
*(dataptr+2*639);
*(dataptr+2*640);
*(dataptr+2*641);
*(dataptr+2*642);
*(dataptr+2*643);
*(dataptr+2*644);
*(dataptr+2*645);
*(dataptr+2*646);
*(dataptr+2*647);
*(dataptr+2*648);
*(dataptr+2*649);
*(dataptr+2*650);
*(dataptr+2*651);
*(dataptr+2*652);
*(dataptr+2*653);
*(dataptr+2*654);
*(dataptr+2*655);
*(dataptr+2*656);
*(dataptr+2*657);
*(dataptr+2*658);
*(dataptr+2*659);
*(dataptr+2*660);
*(dataptr+2*661);
*(dataptr+2*662);
*(dataptr+2*663);
*(dataptr+2*664);
*(dataptr+2*665);
*(dataptr+2*666);
*(dataptr+2*667);
*(dataptr+2*668);
*(dataptr+2*669);
*(dataptr+2*670);
*(dataptr+2*671);
*(dataptr+2*672);
*(dataptr+2*673);
*(dataptr+2*674);
*(dataptr+2*675);
*(dataptr+2*676);
*(dataptr+2*677);
*(dataptr+2*678);
*(dataptr+2*679);
*(dataptr+2*680);
*(dataptr+2*681);
*(dataptr+2*682);
*(dataptr+2*683);
*(dataptr+2*684);
*(dataptr+2*685);
*(dataptr+2*686);
*(dataptr+2*687);
*(dataptr+2*688);
*(dataptr+2*689);
*(dataptr+2*690);
*(dataptr+2*691);
*(dataptr+2*692);
*(dataptr+2*693);
*(dataptr+2*694);
*(dataptr+2*695);
*(dataptr+2*696);
*(dataptr+2*697);
*(dataptr+2*698);
*(dataptr+2*699);
*(dataptr+2*700);
*(dataptr+2*701);
*(dataptr+2*702);
*(dataptr+2*703);
*(dataptr+2*704);
*(dataptr+2*705);
*(dataptr+2*706);
*(dataptr+2*707);
*(dataptr+2*708);
*(dataptr+2*709);
*(dataptr+2*710);
*(dataptr+2*711);
*(dataptr+2*712);
*(dataptr+2*713);
*(dataptr+2*714);
*(dataptr+2*715);
*(dataptr+2*716);
*(dataptr+2*717);
*(dataptr+2*718);
*(dataptr+2*719);
*(dataptr+2*720);
*(dataptr+2*721);
*(dataptr+2*722);
*(dataptr+2*723);
*(dataptr+2*724);
*(dataptr+2*725);
*(dataptr+2*726);
*(dataptr+2*727);
*(dataptr+2*728);
*(dataptr+2*729);
*(dataptr+2*730);
*(dataptr+2*731);
*(dataptr+2*732);
*(dataptr+2*733);
*(dataptr+2*734);
*(dataptr+2*735);
*(dataptr+2*736);
*(dataptr+2*737);
*(dataptr+2*738);
*(dataptr+2*739);
*(dataptr+2*740);
*(dataptr+2*741);
*(dataptr+2*742);
*(dataptr+2*743);
*(dataptr+2*744);
*(dataptr+2*745);
*(dataptr+2*746);
*(dataptr+2*747);
*(dataptr+2*748);
*(dataptr+2*749);
*(dataptr+2*750);
*(dataptr+2*751);
*(dataptr+2*752);
*(dataptr+2*753);
*(dataptr+2*754);
*(dataptr+2*755);
*(dataptr+2*756);
*(dataptr+2*757);
*(dataptr+2*758);
*(dataptr+2*759);
*(dataptr+2*760);
*(dataptr+2*761);
*(dataptr+2*762);
*(dataptr+2*763);
*(dataptr+2*764);
*(dataptr+2*765);
*(dataptr+2*766);
*(dataptr+2*767);
*(dataptr+2*768);
*(dataptr+2*769);
*(dataptr+2*770);
*(dataptr+2*771);
*(dataptr+2*772);
*(dataptr+2*773);
*(dataptr+2*774);
*(dataptr+2*775);
*(dataptr+2*776);
*(dataptr+2*777);
*(dataptr+2*778);
*(dataptr+2*779);
*(dataptr+2*780);
*(dataptr+2*781);
*(dataptr+2*782);
*(dataptr+2*783);
*(dataptr+2*784);
*(dataptr+2*785);
*(dataptr+2*786);
*(dataptr+2*787);
*(dataptr+2*788);
*(dataptr+2*789);
*(dataptr+2*790);
*(dataptr+2*791);
*(dataptr+2*792);
*(dataptr+2*793);
*(dataptr+2*794);
*(dataptr+2*795);
*(dataptr+2*796);
*(dataptr+2*797);
*(dataptr+2*798);
*(dataptr+2*799);
*(dataptr+2*800);
*(dataptr+2*801);
*(dataptr+2*802);
*(dataptr+2*803);
*(dataptr+2*804);
*(dataptr+2*805);
*(dataptr+2*806);
*(dataptr+2*807);
*(dataptr+2*808);
*(dataptr+2*809);
*(dataptr+2*810);
*(dataptr+2*811);
*(dataptr+2*812);
*(dataptr+2*813);
*(dataptr+2*814);
*(dataptr+2*815);
*(dataptr+2*816);
*(dataptr+2*817);
*(dataptr+2*818);
*(dataptr+2*819);
*(dataptr+2*820);
*(dataptr+2*821);
*(dataptr+2*822);
*(dataptr+2*823);
*(dataptr+2*824);
*(dataptr+2*825);
*(dataptr+2*826);
*(dataptr+2*827);
*(dataptr+2*828);
*(dataptr+2*829);
*(dataptr+2*830);
*(dataptr+2*831);
*(dataptr+2*832);
*(dataptr+2*833);
*(dataptr+2*834);
*(dataptr+2*835);
*(dataptr+2*836);
*(dataptr+2*837);
*(dataptr+2*838);
*(dataptr+2*839);
*(dataptr+2*840);
*(dataptr+2*841);
*(dataptr+2*842);
*(dataptr+2*843);
*(dataptr+2*844);
*(dataptr+2*845);
*(dataptr+2*846);
*(dataptr+2*847);
*(dataptr+2*848);
*(dataptr+2*849);
*(dataptr+2*850);
*(dataptr+2*851);
*(dataptr+2*852);
*(dataptr+2*853);
*(dataptr+2*854);
*(dataptr+2*855);
*(dataptr+2*856);
*(dataptr+2*857);
*(dataptr+2*858);
*(dataptr+2*859);
*(dataptr+2*860);
*(dataptr+2*861);
*(dataptr+2*862);
*(dataptr+2*863);
*(dataptr+2*864);
*(dataptr+2*865);
*(dataptr+2*866);
*(dataptr+2*867);
*(dataptr+2*868);
*(dataptr+2*869);
*(dataptr+2*870);
*(dataptr+2*871);
*(dataptr+2*872);
*(dataptr+2*873);
*(dataptr+2*874);
*(dataptr+2*875);
*(dataptr+2*876);
*(dataptr+2*877);
*(dataptr+2*878);
*(dataptr+2*879);
*(dataptr+2*880);
*(dataptr+2*881);
*(dataptr+2*882);
*(dataptr+2*883);
*(dataptr+2*884);
*(dataptr+2*885);
*(dataptr+2*886);
*(dataptr+2*887);
*(dataptr+2*888);
*(dataptr+2*889);
*(dataptr+2*890);
*(dataptr+2*891);
*(dataptr+2*892);
*(dataptr+2*893);
*(dataptr+2*894);
*(dataptr+2*895);
*(dataptr+2*896);
*(dataptr+2*897);
*(dataptr+2*898);
*(dataptr+2*899);
*(dataptr+2*900);
*(dataptr+2*901);
*(dataptr+2*902);
*(dataptr+2*903);
*(dataptr+2*904);
*(dataptr+2*905);
*(dataptr+2*906);
*(dataptr+2*907);
*(dataptr+2*908);
*(dataptr+2*909);
*(dataptr+2*910);
*(dataptr+2*911);
*(dataptr+2*912);
*(dataptr+2*913);
*(dataptr+2*914);
*(dataptr+2*915);
*(dataptr+2*916);
*(dataptr+2*917);
*(dataptr+2*918);
*(dataptr+2*919);
*(dataptr+2*920);
*(dataptr+2*921);
*(dataptr+2*922);
*(dataptr+2*923);
*(dataptr+2*924);
*(dataptr+2*925);
*(dataptr+2*926);
*(dataptr+2*927);
*(dataptr+2*928);
*(dataptr+2*929);
*(dataptr+2*930);
*(dataptr+2*931);
*(dataptr+2*932);
*(dataptr+2*933);
*(dataptr+2*934);
*(dataptr+2*935);
*(dataptr+2*936);
*(dataptr+2*937);
*(dataptr+2*938);
*(dataptr+2*939);
*(dataptr+2*940);
*(dataptr+2*941);
*(dataptr+2*942);
*(dataptr+2*943);
*(dataptr+2*944);
*(dataptr+2*945);
*(dataptr+2*946);
*(dataptr+2*947);
*(dataptr+2*948);
*(dataptr+2*949);
*(dataptr+2*950);
*(dataptr+2*951);
*(dataptr+2*952);
*(dataptr+2*953);
*(dataptr+2*954);
*(dataptr+2*955);
*(dataptr+2*956);
*(dataptr+2*957);
*(dataptr+2*958);
*(dataptr+2*959);
*(dataptr+2*960);
*(dataptr+2*961);
*(dataptr+2*962);
*(dataptr+2*963);
*(dataptr+2*964);
*(dataptr+2*965);
*(dataptr+2*966);
*(dataptr+2*967);
*(dataptr+2*968);
*(dataptr+2*969);
*(dataptr+2*970);
*(dataptr+2*971);
*(dataptr+2*972);
*(dataptr+2*973);
*(dataptr+2*974);
*(dataptr+2*975);
*(dataptr+2*976);
*(dataptr+2*977);
*(dataptr+2*978);
*(dataptr+2*979);
*(dataptr+2*980);
*(dataptr+2*981);
*(dataptr+2*982);
*(dataptr+2*983);
*(dataptr+2*984);
*(dataptr+2*985);
*(dataptr+2*986);
*(dataptr+2*987);
*(dataptr+2*988);
*(dataptr+2*989);
*(dataptr+2*990);
*(dataptr+2*991);
*(dataptr+2*992);
*(dataptr+2*993);
*(dataptr+2*994);
*(dataptr+2*995);
*(dataptr+2*996);
*(dataptr+2*997);
*(dataptr+2*998);
*(dataptr+2*999);
*(dataptr+2*1000);
*(dataptr+2*1001);
*(dataptr+2*1002);
*(dataptr+2*1003);
*(dataptr+2*1004);
*(dataptr+2*1005);
*(dataptr+2*1006);
*(dataptr+2*1007);
*(dataptr+2*1008);
*(dataptr+2*1009);
*(dataptr+2*1010);
*(dataptr+2*1011);
*(dataptr+2*1012);
*(dataptr+2*1013);
*(dataptr+2*1014);
*(dataptr+2*1015);
*(dataptr+2*1016);
*(dataptr+2*1017);
*(dataptr+2*1018);
*(dataptr+2*1019);
*(dataptr+2*1020);
*(dataptr+2*1021);
*(dataptr+2*1022);
*(dataptr+2*1023);
*(dataptr+2*1024);
*(dataptr+2*1025);
*(dataptr+2*1026);
*(dataptr+2*1027);
*(dataptr+2*1028);
*(dataptr+2*1029);
*(dataptr+2*1030);
*(dataptr+2*1031);
*(dataptr+2*1032);
*(dataptr+2*1033);
*(dataptr+2*1034);
*(dataptr+2*1035);
*(dataptr+2*1036);
*(dataptr+2*1037);
*(dataptr+2*1038);
*(dataptr+2*1039);
*(dataptr+2*1040);
*(dataptr+2*1041);
*(dataptr+2*1042);
*(dataptr+2*1043);
*(dataptr+2*1044);
*(dataptr+2*1045);
*(dataptr+2*1046);
*(dataptr+2*1047);
*(dataptr+2*1048);
*(dataptr+2*1049);
*(dataptr+2*1050);
*(dataptr+2*1051);
*(dataptr+2*1052);
*(dataptr+2*1053);
*(dataptr+2*1054);
*(dataptr+2*1055);
*(dataptr+2*1056);
*(dataptr+2*1057);
*(dataptr+2*1058);
*(dataptr+2*1059);
*(dataptr+2*1060);
*(dataptr+2*1061);
*(dataptr+2*1062);
*(dataptr+2*1063);
*(dataptr+2*1064);
*(dataptr+2*1065);
*(dataptr+2*1066);
*(dataptr+2*1067);
*(dataptr+2*1068);
*(dataptr+2*1069);
*(dataptr+2*1070);
*(dataptr+2*1071);
*(dataptr+2*1072);
*(dataptr+2*1073);
*(dataptr+2*1074);
*(dataptr+2*1075);
*(dataptr+2*1076);
*(dataptr+2*1077);
*(dataptr+2*1078);
*(dataptr+2*1079);
*(dataptr+2*1080);
*(dataptr+2*1081);
*(dataptr+2*1082);
*(dataptr+2*1083);
*(dataptr+2*1084);
*(dataptr+2*1085);
*(dataptr+2*1086);
*(dataptr+2*1087);
*(dataptr+2*1088);
*(dataptr+2*1089);
*(dataptr+2*1090);
*(dataptr+2*1091);
*(dataptr+2*1092);
*(dataptr+2*1093);
*(dataptr+2*1094);
*(dataptr+2*1095);
*(dataptr+2*1096);
*(dataptr+2*1097);
*(dataptr+2*1098);
*(dataptr+2*1099);
*(dataptr+2*1100);
*(dataptr+2*1101);
*(dataptr+2*1102);
*(dataptr+2*1103);
*(dataptr+2*1104);
*(dataptr+2*1105);
*(dataptr+2*1106);
*(dataptr+2*1107);
*(dataptr+2*1108);
*(dataptr+2*1109);
*(dataptr+2*1110);
*(dataptr+2*1111);
*(dataptr+2*1112);
*(dataptr+2*1113);
*(dataptr+2*1114);
*(dataptr+2*1115);
*(dataptr+2*1116);
*(dataptr+2*1117);
*(dataptr+2*1118);
*(dataptr+2*1119);
*(dataptr+2*1120);
*(dataptr+2*1121);
*(dataptr+2*1122);
*(dataptr+2*1123);
*(dataptr+2*1124);
*(dataptr+2*1125);
*(dataptr+2*1126);
*(dataptr+2*1127);
*(dataptr+2*1128);
*(dataptr+2*1129);
*(dataptr+2*1130);
*(dataptr+2*1131);
*(dataptr+2*1132);
*(dataptr+2*1133);
*(dataptr+2*1134);
*(dataptr+2*1135);
*(dataptr+2*1136);
*(dataptr+2*1137);
*(dataptr+2*1138);
*(dataptr+2*1139);
*(dataptr+2*1140);
*(dataptr+2*1141);
*(dataptr+2*1142);
*(dataptr+2*1143);
*(dataptr+2*1144);
*(dataptr+2*1145);
*(dataptr+2*1146);
*(dataptr+2*1147);
*(dataptr+2*1148);
*(dataptr+2*1149);
*(dataptr+2*1150);
*(dataptr+2*1151);
*(dataptr+2*1152);
*(dataptr+2*1153);
*(dataptr+2*1154);
*(dataptr+2*1155);
*(dataptr+2*1156);
*(dataptr+2*1157);
*(dataptr+2*1158);
*(dataptr+2*1159);
*(dataptr+2*1160);
*(dataptr+2*1161);
*(dataptr+2*1162);
*(dataptr+2*1163);
*(dataptr+2*1164);
*(dataptr+2*1165);
*(dataptr+2*1166);
*(dataptr+2*1167);
*(dataptr+2*1168);
*(dataptr+2*1169);
*(dataptr+2*1170);
*(dataptr+2*1171);
*(dataptr+2*1172);
*(dataptr+2*1173);
*(dataptr+2*1174);
*(dataptr+2*1175);
*(dataptr+2*1176);
*(dataptr+2*1177);
*(dataptr+2*1178);
*(dataptr+2*1179);
*(dataptr+2*1180);
*(dataptr+2*1181);
*(dataptr+2*1182);
*(dataptr+2*1183);
*(dataptr+2*1184);
*(dataptr+2*1185);
*(dataptr+2*1186);
*(dataptr+2*1187);
*(dataptr+2*1188);
*(dataptr+2*1189);
*(dataptr+2*1190);
*(dataptr+2*1191);
*(dataptr+2*1192);
*(dataptr+2*1193);
*(dataptr+2*1194);
*(dataptr+2*1195);
*(dataptr+2*1196);
*(dataptr+2*1197);
*(dataptr+2*1198);
*(dataptr+2*1199);
*(dataptr+2*1200);
*(dataptr+2*1201);
*(dataptr+2*1202);
*(dataptr+2*1203);
*(dataptr+2*1204);
*(dataptr+2*1205);
*(dataptr+2*1206);
*(dataptr+2*1207);
*(dataptr+2*1208);
*(dataptr+2*1209);
*(dataptr+2*1210);
*(dataptr+2*1211);
*(dataptr+2*1212);
*(dataptr+2*1213);
*(dataptr+2*1214);
*(dataptr+2*1215);
*(dataptr+2*1216);
*(dataptr+2*1217);
*(dataptr+2*1218);
*(dataptr+2*1219);
*(dataptr+2*1220);
*(dataptr+2*1221);
*(dataptr+2*1222);
*(dataptr+2*1223);
*(dataptr+2*1224);
*(dataptr+2*1225);
*(dataptr+2*1226);
*(dataptr+2*1227);
*(dataptr+2*1228);
*(dataptr+2*1229);
*(dataptr+2*1230);
*(dataptr+2*1231);
*(dataptr+2*1232);
*(dataptr+2*1233);
*(dataptr+2*1234);
*(dataptr+2*1235);
*(dataptr+2*1236);
*(dataptr+2*1237);
*(dataptr+2*1238);
*(dataptr+2*1239);
*(dataptr+2*1240);
*(dataptr+2*1241);
*(dataptr+2*1242);
*(dataptr+2*1243);
*(dataptr+2*1244);
*(dataptr+2*1245);
*(dataptr+2*1246);
*(dataptr+2*1247);
*(dataptr+2*1248);
*(dataptr+2*1249);
*(dataptr+2*1250);
*(dataptr+2*1251);
*(dataptr+2*1252);
*(dataptr+2*1253);
*(dataptr+2*1254);
*(dataptr+2*1255);
*(dataptr+2*1256);
*(dataptr+2*1257);
*(dataptr+2*1258);
*(dataptr+2*1259);
*(dataptr+2*1260);
*(dataptr+2*1261);
*(dataptr+2*1262);
*(dataptr+2*1263);
*(dataptr+2*1264);
*(dataptr+2*1265);
*(dataptr+2*1266);
*(dataptr+2*1267);
*(dataptr+2*1268);
*(dataptr+2*1269);
*(dataptr+2*1270);
*(dataptr+2*1271);
*(dataptr+2*1272);
*(dataptr+2*1273);
*(dataptr+2*1274);
*(dataptr+2*1275);
*(dataptr+2*1276);
*(dataptr+2*1277);
*(dataptr+2*1278);
*(dataptr+2*1279);
*(dataptr+2*1280);
*(dataptr+2*1281);
*(dataptr+2*1282);
*(dataptr+2*1283);
*(dataptr+2*1284);
*(dataptr+2*1285);
*(dataptr+2*1286);
*(dataptr+2*1287);
*(dataptr+2*1288);
*(dataptr+2*1289);
*(dataptr+2*1290);
*(dataptr+2*1291);
*(dataptr+2*1292);
*(dataptr+2*1293);
*(dataptr+2*1294);
*(dataptr+2*1295);
*(dataptr+2*1296);
*(dataptr+2*1297);
*(dataptr+2*1298);
*(dataptr+2*1299);
*(dataptr+2*1300);
*(dataptr+2*1301);
*(dataptr+2*1302);
*(dataptr+2*1303);
*(dataptr+2*1304);
*(dataptr+2*1305);
*(dataptr+2*1306);
*(dataptr+2*1307);
*(dataptr+2*1308);
*(dataptr+2*1309);
*(dataptr+2*1310);
*(dataptr+2*1311);
*(dataptr+2*1312);
*(dataptr+2*1313);
*(dataptr+2*1314);
*(dataptr+2*1315);
*(dataptr+2*1316);
*(dataptr+2*1317);
*(dataptr+2*1318);
*(dataptr+2*1319);
*(dataptr+2*1320);
*(dataptr+2*1321);
*(dataptr+2*1322);
*(dataptr+2*1323);
*(dataptr+2*1324);
*(dataptr+2*1325);
*(dataptr+2*1326);
*(dataptr+2*1327);
*(dataptr+2*1328);
*(dataptr+2*1329);
*(dataptr+2*1330);
*(dataptr+2*1331);
*(dataptr+2*1332);
*(dataptr+2*1333);
*(dataptr+2*1334);
*(dataptr+2*1335);
*(dataptr+2*1336);
*(dataptr+2*1337);
*(dataptr+2*1338);
*(dataptr+2*1339);
*(dataptr+2*1340);
*(dataptr+2*1341);
*(dataptr+2*1342);
*(dataptr+2*1343);
*(dataptr+2*1344);
*(dataptr+2*1345);
*(dataptr+2*1346);
*(dataptr+2*1347);
*(dataptr+2*1348);
*(dataptr+2*1349);
*(dataptr+2*1350);
*(dataptr+2*1351);
*(dataptr+2*1352);
*(dataptr+2*1353);
*(dataptr+2*1354);
*(dataptr+2*1355);
*(dataptr+2*1356);
*(dataptr+2*1357);
*(dataptr+2*1358);
*(dataptr+2*1359);
*(dataptr+2*1360);
*(dataptr+2*1361);
*(dataptr+2*1362);
*(dataptr+2*1363);
*(dataptr+2*1364);
*(dataptr+2*1365);
*(dataptr+2*1366);
*(dataptr+2*1367);
*(dataptr+2*1368);
*(dataptr+2*1369);
*(dataptr+2*1370);
*(dataptr+2*1371);
*(dataptr+2*1372);
*(dataptr+2*1373);
*(dataptr+2*1374);
*(dataptr+2*1375);
*(dataptr+2*1376);
*(dataptr+2*1377);
*(dataptr+2*1378);
*(dataptr+2*1379);
*(dataptr+2*1380);
*(dataptr+2*1381);
*(dataptr+2*1382);
*(dataptr+2*1383);
*(dataptr+2*1384);
*(dataptr+2*1385);
*(dataptr+2*1386);
*(dataptr+2*1387);
*(dataptr+2*1388);
*(dataptr+2*1389);
*(dataptr+2*1390);
*(dataptr+2*1391);
*(dataptr+2*1392);
*(dataptr+2*1393);
*(dataptr+2*1394);
*(dataptr+2*1395);
*(dataptr+2*1396);
*(dataptr+2*1397);
*(dataptr+2*1398);
*(dataptr+2*1399);
*(dataptr+2*1400);
*(dataptr+2*1401);
*(dataptr+2*1402);
*(dataptr+2*1403);
*(dataptr+2*1404);
*(dataptr+2*1405);
*(dataptr+2*1406);
*(dataptr+2*1407);
*(dataptr+2*1408);
*(dataptr+2*1409);
*(dataptr+2*1410);
*(dataptr+2*1411);
*(dataptr+2*1412);
*(dataptr+2*1413);
*(dataptr+2*1414);
*(dataptr+2*1415);
*(dataptr+2*1416);
*(dataptr+2*1417);
*(dataptr+2*1418);
*(dataptr+2*1419);
*(dataptr+2*1420);
*(dataptr+2*1421);
*(dataptr+2*1422);
*(dataptr+2*1423);
*(dataptr+2*1424);
*(dataptr+2*1425);
*(dataptr+2*1426);
*(dataptr+2*1427);
*(dataptr+2*1428);
*(dataptr+2*1429);
*(dataptr+2*1430);
*(dataptr+2*1431);
*(dataptr+2*1432);
*(dataptr+2*1433);
*(dataptr+2*1434);
*(dataptr+2*1435);
*(dataptr+2*1436);
*(dataptr+2*1437);
*(dataptr+2*1438);
*(dataptr+2*1439);
*(dataptr+2*1440);
*(dataptr+2*1441);
*(dataptr+2*1442);
*(dataptr+2*1443);
*(dataptr+2*1444);
*(dataptr+2*1445);
*(dataptr+2*1446);
*(dataptr+2*1447);
*(dataptr+2*1448);
*(dataptr+2*1449);
*(dataptr+2*1450);
*(dataptr+2*1451);
*(dataptr+2*1452);
*(dataptr+2*1453);
*(dataptr+2*1454);
*(dataptr+2*1455);
*(dataptr+2*1456);
*(dataptr+2*1457);
*(dataptr+2*1458);
*(dataptr+2*1459);
*(dataptr+2*1460);
*(dataptr+2*1461);
*(dataptr+2*1462);
*(dataptr+2*1463);
*(dataptr+2*1464);
*(dataptr+2*1465);
*(dataptr+2*1466);
*(dataptr+2*1467);
*(dataptr+2*1468);
*(dataptr+2*1469);
*(dataptr+2*1470);
*(dataptr+2*1471);
*(dataptr+2*1472);
*(dataptr+2*1473);
*(dataptr+2*1474);
*(dataptr+2*1475);
*(dataptr+2*1476);
*(dataptr+2*1477);
*(dataptr+2*1478);
*(dataptr+2*1479);
*(dataptr+2*1480);
*(dataptr+2*1481);
*(dataptr+2*1482);
*(dataptr+2*1483);
*(dataptr+2*1484);
*(dataptr+2*1485);
*(dataptr+2*1486);
*(dataptr+2*1487);
*(dataptr+2*1488);
*(dataptr+2*1489);
*(dataptr+2*1490);
*(dataptr+2*1491);
*(dataptr+2*1492);
*(dataptr+2*1493);
*(dataptr+2*1494);
*(dataptr+2*1495);
*(dataptr+2*1496);
*(dataptr+2*1497);
*(dataptr+2*1498);
*(dataptr+2*1499);
*(dataptr+2*1500);
*(dataptr+2*1501);
*(dataptr+2*1502);
*(dataptr+2*1503);
*(dataptr+2*1504);
*(dataptr+2*1505);
*(dataptr+2*1506);
*(dataptr+2*1507);
*(dataptr+2*1508);
*(dataptr+2*1509);
*(dataptr+2*1510);
*(dataptr+2*1511);
*(dataptr+2*1512);
*(dataptr+2*1513);
*(dataptr+2*1514);
*(dataptr+2*1515);
*(dataptr+2*1516);
*(dataptr+2*1517);
*(dataptr+2*1518);
*(dataptr+2*1519);
*(dataptr+2*1520);
*(dataptr+2*1521);
*(dataptr+2*1522);
*(dataptr+2*1523);
*(dataptr+2*1524);
*(dataptr+2*1525);
*(dataptr+2*1526);
*(dataptr+2*1527);
*(dataptr+2*1528);
*(dataptr+2*1529);
*(dataptr+2*1530);
*(dataptr+2*1531);
*(dataptr+2*1532);
*(dataptr+2*1533);
*(dataptr+2*1534);
*(dataptr+2*1535);
*(dataptr+2*1536);
*(dataptr+2*1537);
*(dataptr+2*1538);
*(dataptr+2*1539);
*(dataptr+2*1540);
*(dataptr+2*1541);
*(dataptr+2*1542);
*(dataptr+2*1543);
*(dataptr+2*1544);
*(dataptr+2*1545);
*(dataptr+2*1546);
*(dataptr+2*1547);
*(dataptr+2*1548);
*(dataptr+2*1549);
*(dataptr+2*1550);
*(dataptr+2*1551);
*(dataptr+2*1552);
*(dataptr+2*1553);
*(dataptr+2*1554);
*(dataptr+2*1555);
*(dataptr+2*1556);
*(dataptr+2*1557);
*(dataptr+2*1558);
*(dataptr+2*1559);
*(dataptr+2*1560);
*(dataptr+2*1561);
*(dataptr+2*1562);
*(dataptr+2*1563);
*(dataptr+2*1564);
*(dataptr+2*1565);
*(dataptr+2*1566);
*(dataptr+2*1567);
*(dataptr+2*1568);
*(dataptr+2*1569);
*(dataptr+2*1570);
*(dataptr+2*1571);
*(dataptr+2*1572);
*(dataptr+2*1573);
*(dataptr+2*1574);
*(dataptr+2*1575);
*(dataptr+2*1576);
*(dataptr+2*1577);
*(dataptr+2*1578);
*(dataptr+2*1579);
*(dataptr+2*1580);
*(dataptr+2*1581);
*(dataptr+2*1582);
*(dataptr+2*1583);
*(dataptr+2*1584);
*(dataptr+2*1585);
*(dataptr+2*1586);
*(dataptr+2*1587);
*(dataptr+2*1588);
*(dataptr+2*1589);
*(dataptr+2*1590);
*(dataptr+2*1591);
*(dataptr+2*1592);
*(dataptr+2*1593);
*(dataptr+2*1594);
*(dataptr+2*1595);
*(dataptr+2*1596);
*(dataptr+2*1597);
*(dataptr+2*1598);
*(dataptr+2*1599);
*(dataptr+2*1600);
*(dataptr+2*1601);
*(dataptr+2*1602);
*(dataptr+2*1603);
*(dataptr+2*1604);
*(dataptr+2*1605);
*(dataptr+2*1606);
*(dataptr+2*1607);
*(dataptr+2*1608);
*(dataptr+2*1609);
*(dataptr+2*1610);
*(dataptr+2*1611);
*(dataptr+2*1612);
*(dataptr+2*1613);
*(dataptr+2*1614);
*(dataptr+2*1615);
*(dataptr+2*1616);
*(dataptr+2*1617);
*(dataptr+2*1618);
*(dataptr+2*1619);
*(dataptr+2*1620);
*(dataptr+2*1621);
*(dataptr+2*1622);
*(dataptr+2*1623);
*(dataptr+2*1624);
*(dataptr+2*1625);
*(dataptr+2*1626);
*(dataptr+2*1627);
*(dataptr+2*1628);
*(dataptr+2*1629);
*(dataptr+2*1630);
*(dataptr+2*1631);
*(dataptr+2*1632);
*(dataptr+2*1633);
*(dataptr+2*1634);
*(dataptr+2*1635);
*(dataptr+2*1636);
*(dataptr+2*1637);
*(dataptr+2*1638);
*(dataptr+2*1639);
*(dataptr+2*1640);
*(dataptr+2*1641);
*(dataptr+2*1642);
*(dataptr+2*1643);
*(dataptr+2*1644);
*(dataptr+2*1645);
*(dataptr+2*1646);
*(dataptr+2*1647);
*(dataptr+2*1648);
*(dataptr+2*1649);
*(dataptr+2*1650);
*(dataptr+2*1651);
*(dataptr+2*1652);
*(dataptr+2*1653);
*(dataptr+2*1654);
*(dataptr+2*1655);
*(dataptr+2*1656);
*(dataptr+2*1657);
*(dataptr+2*1658);
*(dataptr+2*1659);
*(dataptr+2*1660);
*(dataptr+2*1661);
*(dataptr+2*1662);
*(dataptr+2*1663);
*(dataptr+2*1664);
*(dataptr+2*1665);
*(dataptr+2*1666);
*(dataptr+2*1667);
*(dataptr+2*1668);
*(dataptr+2*1669);
*(dataptr+2*1670);
*(dataptr+2*1671);
*(dataptr+2*1672);
*(dataptr+2*1673);
*(dataptr+2*1674);
*(dataptr+2*1675);
*(dataptr+2*1676);
*(dataptr+2*1677);
*(dataptr+2*1678);
*(dataptr+2*1679);
*(dataptr+2*1680);
*(dataptr+2*1681);
*(dataptr+2*1682);
*(dataptr+2*1683);
*(dataptr+2*1684);
*(dataptr+2*1685);
*(dataptr+2*1686);
*(dataptr+2*1687);
*(dataptr+2*1688);
*(dataptr+2*1689);
*(dataptr+2*1690);
*(dataptr+2*1691);
*(dataptr+2*1692);
*(dataptr+2*1693);
*(dataptr+2*1694);
*(dataptr+2*1695);
*(dataptr+2*1696);
*(dataptr+2*1697);
*(dataptr+2*1698);
*(dataptr+2*1699);
*(dataptr+2*1700);
*(dataptr+2*1701);
*(dataptr+2*1702);
*(dataptr+2*1703);
*(dataptr+2*1704);
*(dataptr+2*1705);
*(dataptr+2*1706);
*(dataptr+2*1707);
*(dataptr+2*1708);
*(dataptr+2*1709);
*(dataptr+2*1710);
*(dataptr+2*1711);
*(dataptr+2*1712);
*(dataptr+2*1713);
*(dataptr+2*1714);
*(dataptr+2*1715);
*(dataptr+2*1716);
*(dataptr+2*1717);
*(dataptr+2*1718);
*(dataptr+2*1719);
*(dataptr+2*1720);
*(dataptr+2*1721);
*(dataptr+2*1722);
*(dataptr+2*1723);
*(dataptr+2*1724);
*(dataptr+2*1725);
*(dataptr+2*1726);
*(dataptr+2*1727);
*(dataptr+2*1728);
*(dataptr+2*1729);
*(dataptr+2*1730);
*(dataptr+2*1731);
*(dataptr+2*1732);
*(dataptr+2*1733);
*(dataptr+2*1734);
*(dataptr+2*1735);
*(dataptr+2*1736);
*(dataptr+2*1737);
*(dataptr+2*1738);
*(dataptr+2*1739);
*(dataptr+2*1740);
*(dataptr+2*1741);
*(dataptr+2*1742);
*(dataptr+2*1743);
*(dataptr+2*1744);
*(dataptr+2*1745);
*(dataptr+2*1746);
*(dataptr+2*1747);
*(dataptr+2*1748);
*(dataptr+2*1749);
*(dataptr+2*1750);
*(dataptr+2*1751);
*(dataptr+2*1752);
*(dataptr+2*1753);
*(dataptr+2*1754);
*(dataptr+2*1755);
*(dataptr+2*1756);
*(dataptr+2*1757);
*(dataptr+2*1758);
*(dataptr+2*1759);
*(dataptr+2*1760);
*(dataptr+2*1761);
*(dataptr+2*1762);
*(dataptr+2*1763);
*(dataptr+2*1764);
*(dataptr+2*1765);
*(dataptr+2*1766);
*(dataptr+2*1767);
*(dataptr+2*1768);
*(dataptr+2*1769);
*(dataptr+2*1770);
*(dataptr+2*1771);
*(dataptr+2*1772);
*(dataptr+2*1773);
*(dataptr+2*1774);
*(dataptr+2*1775);
*(dataptr+2*1776);
*(dataptr+2*1777);
*(dataptr+2*1778);
*(dataptr+2*1779);
*(dataptr+2*1780);
*(dataptr+2*1781);
*(dataptr+2*1782);
*(dataptr+2*1783);
*(dataptr+2*1784);
*(dataptr+2*1785);
*(dataptr+2*1786);
*(dataptr+2*1787);
*(dataptr+2*1788);
*(dataptr+2*1789);
*(dataptr+2*1790);
*(dataptr+2*1791);
*(dataptr+2*1792);
*(dataptr+2*1793);
*(dataptr+2*1794);
*(dataptr+2*1795);
*(dataptr+2*1796);
*(dataptr+2*1797);
*(dataptr+2*1798);
*(dataptr+2*1799);
*(dataptr+2*1800);
*(dataptr+2*1801);
*(dataptr+2*1802);
*(dataptr+2*1803);
*(dataptr+2*1804);
*(dataptr+2*1805);
*(dataptr+2*1806);
*(dataptr+2*1807);
*(dataptr+2*1808);
*(dataptr+2*1809);
*(dataptr+2*1810);
*(dataptr+2*1811);
*(dataptr+2*1812);
*(dataptr+2*1813);
*(dataptr+2*1814);
*(dataptr+2*1815);
*(dataptr+2*1816);
*(dataptr+2*1817);
*(dataptr+2*1818);
*(dataptr+2*1819);
*(dataptr+2*1820);
*(dataptr+2*1821);
*(dataptr+2*1822);
*(dataptr+2*1823);
*(dataptr+2*1824);
*(dataptr+2*1825);
*(dataptr+2*1826);
*(dataptr+2*1827);
*(dataptr+2*1828);
*(dataptr+2*1829);
*(dataptr+2*1830);
*(dataptr+2*1831);
*(dataptr+2*1832);
*(dataptr+2*1833);
*(dataptr+2*1834);
*(dataptr+2*1835);
*(dataptr+2*1836);
*(dataptr+2*1837);
*(dataptr+2*1838);
*(dataptr+2*1839);
*(dataptr+2*1840);
*(dataptr+2*1841);
*(dataptr+2*1842);
*(dataptr+2*1843);
*(dataptr+2*1844);
*(dataptr+2*1845);
*(dataptr+2*1846);
*(dataptr+2*1847);
*(dataptr+2*1848);
*(dataptr+2*1849);
*(dataptr+2*1850);
*(dataptr+2*1851);
*(dataptr+2*1852);
*(dataptr+2*1853);
*(dataptr+2*1854);
*(dataptr+2*1855);
*(dataptr+2*1856);
*(dataptr+2*1857);
*(dataptr+2*1858);
*(dataptr+2*1859);
*(dataptr+2*1860);
*(dataptr+2*1861);
*(dataptr+2*1862);
*(dataptr+2*1863);
*(dataptr+2*1864);
*(dataptr+2*1865);
*(dataptr+2*1866);
*(dataptr+2*1867);
*(dataptr+2*1868);
*(dataptr+2*1869);
*(dataptr+2*1870);
*(dataptr+2*1871);
*(dataptr+2*1872);
*(dataptr+2*1873);
*(dataptr+2*1874);
*(dataptr+2*1875);
*(dataptr+2*1876);
*(dataptr+2*1877);
*(dataptr+2*1878);
*(dataptr+2*1879);
*(dataptr+2*1880);
*(dataptr+2*1881);
*(dataptr+2*1882);
*(dataptr+2*1883);
*(dataptr+2*1884);
*(dataptr+2*1885);
*(dataptr+2*1886);
*(dataptr+2*1887);
*(dataptr+2*1888);
*(dataptr+2*1889);
*(dataptr+2*1890);
*(dataptr+2*1891);
*(dataptr+2*1892);
*(dataptr+2*1893);
*(dataptr+2*1894);
*(dataptr+2*1895);
*(dataptr+2*1896);
*(dataptr+2*1897);
*(dataptr+2*1898);
*(dataptr+2*1899);
*(dataptr+2*1900);
*(dataptr+2*1901);
*(dataptr+2*1902);
*(dataptr+2*1903);
*(dataptr+2*1904);
*(dataptr+2*1905);
*(dataptr+2*1906);
*(dataptr+2*1907);
*(dataptr+2*1908);
*(dataptr+2*1909);
*(dataptr+2*1910);
*(dataptr+2*1911);
*(dataptr+2*1912);
*(dataptr+2*1913);
*(dataptr+2*1914);
*(dataptr+2*1915);
*(dataptr+2*1916);
*(dataptr+2*1917);
*(dataptr+2*1918);
*(dataptr+2*1919);
*(dataptr+2*1920);
*(dataptr+2*1921);
*(dataptr+2*1922);
*(dataptr+2*1923);
*(dataptr+2*1924);
*(dataptr+2*1925);
*(dataptr+2*1926);
*(dataptr+2*1927);
*(dataptr+2*1928);
*(dataptr+2*1929);
*(dataptr+2*1930);
*(dataptr+2*1931);
*(dataptr+2*1932);
*(dataptr+2*1933);
*(dataptr+2*1934);
*(dataptr+2*1935);
*(dataptr+2*1936);
*(dataptr+2*1937);
*(dataptr+2*1938);
*(dataptr+2*1939);
*(dataptr+2*1940);
*(dataptr+2*1941);
*(dataptr+2*1942);
*(dataptr+2*1943);
*(dataptr+2*1944);
*(dataptr+2*1945);
*(dataptr+2*1946);
*(dataptr+2*1947);
*(dataptr+2*1948);
*(dataptr+2*1949);
*(dataptr+2*1950);
*(dataptr+2*1951);
*(dataptr+2*1952);
*(dataptr+2*1953);
*(dataptr+2*1954);
*(dataptr+2*1955);
*(dataptr+2*1956);
*(dataptr+2*1957);
*(dataptr+2*1958);
*(dataptr+2*1959);
*(dataptr+2*1960);
*(dataptr+2*1961);
*(dataptr+2*1962);
*(dataptr+2*1963);
*(dataptr+2*1964);
*(dataptr+2*1965);
*(dataptr+2*1966);
*(dataptr+2*1967);
*(dataptr+2*1968);
*(dataptr+2*1969);
*(dataptr+2*1970);
*(dataptr+2*1971);
*(dataptr+2*1972);
*(dataptr+2*1973);
*(dataptr+2*1974);
*(dataptr+2*1975);
*(dataptr+2*1976);
*(dataptr+2*1977);
*(dataptr+2*1978);
*(dataptr+2*1979);
*(dataptr+2*1980);
*(dataptr+2*1981);
*(dataptr+2*1982);
*(dataptr+2*1983);
*(dataptr+2*1984);
*(dataptr+2*1985);
*(dataptr+2*1986);
*(dataptr+2*1987);
*(dataptr+2*1988);
*(dataptr+2*1989);
*(dataptr+2*1990);
*(dataptr+2*1991);
*(dataptr+2*1992);
*(dataptr+2*1993);
*(dataptr+2*1994);
*(dataptr+2*1995);
*(dataptr+2*1996);
*(dataptr+2*1997);
*(dataptr+2*1998);
*(dataptr+2*1999);
*(dataptr+2*2000);
*(dataptr+2*2001);
*(dataptr+2*2002);
*(dataptr+2*2003);
*(dataptr+2*2004);
*(dataptr+2*2005);
*(dataptr+2*2006);
*(dataptr+2*2007);
*(dataptr+2*2008);
*(dataptr+2*2009);
*(dataptr+2*2010);
*(dataptr+2*2011);
*(dataptr+2*2012);
*(dataptr+2*2013);
*(dataptr+2*2014);
*(dataptr+2*2015);
*(dataptr+2*2016);
*(dataptr+2*2017);
*(dataptr+2*2018);
*(dataptr+2*2019);
*(dataptr+2*2020);
*(dataptr+2*2021);
*(dataptr+2*2022);
*(dataptr+2*2023);
*(dataptr+2*2024);
*(dataptr+2*2025);
*(dataptr+2*2026);
*(dataptr+2*2027);
*(dataptr+2*2028);
*(dataptr+2*2029);
*(dataptr+2*2030);
*(dataptr+2*2031);
*(dataptr+2*2032);
*(dataptr+2*2033);
*(dataptr+2*2034);
*(dataptr+2*2035);
*(dataptr+2*2036);
*(dataptr+2*2037);
*(dataptr+2*2038);
*(dataptr+2*2039);
*(dataptr+2*2040);
*(dataptr+2*2041);
*(dataptr+2*2042);
*(dataptr+2*2043);
*(dataptr+2*2044);
*(dataptr+2*2045);
*(dataptr+2*2046);
*(dataptr+2*2047);
}
