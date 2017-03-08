#!/usr/bin/php
<?php
/**
 * do_stuff.php
 *
 *  Write smstools3 sms data to json files
 *  use this file as eventhandler in smsd.conf
 *
 *
 * @author     Nikolai Pulman
 * @copyright  2017 Nikolai Pulman
 * @license    This software may be modified and distributed under the terms of the BSD license.
 */



$sms_type = $argv[1];
$sms_file = $argv[2];
$conversation_location = "/var/www/html/sms";
$conversation_file = "";

$sms_file_content = file_get_contents($sms_file);
$i = strpos($sms_file_content, "\n\n");
$sms_headers_part = substr($sms_file_content, 0, $i);
$sms_message_body = substr($sms_file_content, $i + 2);
$sms_header_lines = explode("\n", $sms_headers_part);
$sms_headers = array();

foreach ($sms_header_lines as $header)
{
  $i = strpos($header, ":");
  if ($i !== false)
    $sms_headers[substr($header, 0, $i)] = substr($header, $i + 2);
}

#Get phone number/conversation filename
switch ($sms_type) {
    case "SENT":
        $conversation_file =  $sms_headers["To"];
	$received = "";
        break;
    case "RECEIVED":
        $conversation_file =  $sms_headers["From"];
	$received = $sms_headers["Received"];
        break;
}

#Check if file exist and if not create json header
if(file_exists($conversation_location . "/"  . $conversation_file)){
	#Open file
	$json = json_decode(file_get_contents($conversation_location . "/"  . $conversation_file), true);
} else {
	$json["Number"] = $conversation_file;
	$json["Nickname"]= "Unknown";
	$json["Messages"] = array();
}

#Collect new sms data
$new = array();
$new["Type"] = $sms_type;
$new["SENT"] = $sms_headers["Sent"];
$new["RECEIVED"] = $received;
$new ["TEXT"] = $sms_message_body;

#add $new to sms arrays
array_push($json["Messages"],$new);

#Encode as JSON
$stringData = json_encode($json, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE);

#Write new json to file
$fh = fopen($conversation_location . "/"  . $conversation_file, 'wb') or die("can't open file");
fwrite($fh, $stringData );
fclose($fh);
?>
