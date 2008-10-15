<?php

/**
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * <franksp@internl.net> wrote this file. As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return Frank Spijkerman
 * ----------------------------------------------------------------------------
 *
 * @package savonet
 * @copyright 2008, Frank Spijkerman
 *  for the Savonet Project
 */

include dirname(__FILE__) . "/savonet.inc";

$sav = new savonet();

$sav->connect();
$sav->is_alive();
$sav->stream_list();

print "Now playing: " . $sav->now_playing() . "\n";
print "Skipping song...\n";
$sav->skip("radio(dot)ogg");

$sav->queue_list("request_queue");
//$sav->queue_push("request_queue", "/home/frank/Music/The Prodigy - The Fat Of The Land/07 - Narayan.mp3");

