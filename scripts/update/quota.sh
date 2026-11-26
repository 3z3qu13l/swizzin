#!/bin/bash

if [[ -f /install/.quota.lock ]]; then
    #shellcheck source=sources/functions/quota
    . /etc/swizzin/sources/functions/quota
    # also rewrites the rules that sudo-rs rejects (Ubuntu 26.04)
    if ! grep -qs QUOTA /etc/sudoers.d/quota || ! visudo -cqf /etc/sudoers.d/quota > /dev/null 2>&1; then
        echo_progress_start "Updating sudoers for quota"
        # on failure the old file stays in place; do not abort the rest of box update
        if quota_sudoers; then echo_progress_done; fi
    fi
fi
