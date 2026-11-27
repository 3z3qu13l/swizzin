<?php
// Public download of a share: /share.php/<link>. The link names its user, set before ruTorrent loads: ruTorrent
// keeps the user, its profile and its settings from its first call
use Flm\Helper;
use Flm\Share\Crypt;
use Flm\Share\FileManagerShare;

require_once __DIR__ . '/src/Crypt.php';
$config = include __DIR__ . '/conf.php';

$user = $token = '';
try {
    Crypt::setEncryptionKey($config['key']);
    $share = json_decode(Crypt::fromEncoded(trim($_SERVER['PATH_INFO'] ?? '', '/'))->getString(), true);
    $user = $share[0] ?? '';
    $token = $share[1] ?? '';
} catch (Throwable $err) {
}
// an empty key decodes links anyone can write
if ($config['key'] === '' || !is_string($user) || !is_string($token) || !preg_match('/^[a-z0-9_-]+$/', $user)
    || !preg_match('/^[A-Za-z0-9]{32}$/', $token)
    || !is_dir(__DIR__ . '/../../conf/users/' . $user)) {
    http_response_code(404);
    die('No such file or it expired');
}
$_SERVER['REMOTE_USER'] = $user;

include __DIR__ . '/boot.php';

try {
    $c = new FileManagerShare(array_merge(Helper::getConfig(), ['share' => $config]));
    $c->downloadShare($token);
} catch (Throwable $err) {
    FileUtil::toLog($err);
    http_response_code(404);
    die('No such file or it expired');
}
