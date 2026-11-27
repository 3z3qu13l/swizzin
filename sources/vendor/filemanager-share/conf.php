<?php
// duration & links limits
// 0 = unlimited
// not $conf: ruTorrent 5 keeps its own settings in that global

// max expire time for a share in hours
$fmShareLimits['duration'] = 24; // 0 - unlimited

// max links per user
$fmShareLimits['links'] = 0; // 0 - unlimited

return [
    'limits' => $fmShareLimits,

    // whether a password is mandatory for link creation
    'require_password' => false,

    // url of share.php, linked by swizzin as /fancyindex/share.php
    'endpoint' => 'https://' . ($_SERVER['HTTP_HOST'] ?? '') . '/fancyindex/share.php',

    // key used for storing encrypted data: written by swizzin, readable by ruTorrent's PHP account only
    "key" => trim((string) @file_get_contents('/install/.rutorrent.share.key')),

    // automatically remove shares - only when removing the file or the containing directory
    "remove_share_on_file_delete" => false,

    // automatically remove expired shares - called only when removing
    "purge_expired_shares" => true
];
