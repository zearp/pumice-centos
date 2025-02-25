#!/usr/bin/gjs -m

/*
 * pumice-welcome: first-login "Install to Hard Drive or Try It" popup.
 *
 * CentOS Stream / Rocky Linux's anaconda-liveinst package (unlike Fedora's
 * anaconda-live) does not ship any GUI welcome screen -- only /usr/bin/liveinst,
 * /usr/share/applications/liveinst.desktop, and the liveinst-setup.desktop
 * autostart entry that copies an icon to the Desktop. There is no
 * /usr/share/anaconda/gnome directory and no fedora-welcome binary on EL10.
 *
 * This script is a from-scratch equivalent, structurally modelled on
 * upstream anaconda's data/liveinst/gnome/fedora-welcome.js (GPL-2.0-or-later,
 * Copyright (C) 2012 Red Hat, Inc.), adapted to:
 *   - not assume Gio.DesktopAppInfo.new('anaconda.desktop'/'liveinst.desktop')
 *     resolves the way it does in a real GNOME app-info cache on a live image
 *     (untested on kiwi-built media) -- instead directly Exec's /usr/bin/liveinst.
 *   - use a generic freedesktop icon-naming-spec icon (system-software-install)
 *     instead of Fedora's branded fedora-logo-icon, which does not exist here.
 */

import Adw from 'gi://Adw?version=1';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
import Gtk from 'gi://Gtk?version=4.0';

import {gettext as _} from 'gettext';
import Gettext from 'gettext';

import {programArgs, programInvocationName} from 'system';

const OS_RELEASE = '/etc/os-release';
const LIVEINST_BIN = '/usr/bin/liveinst';

function getOsName() {
    try {
        const osRelease = Gio.File.new_for_path(OS_RELEASE);
        const contents = osRelease.load_contents(null)[1];
        const lines = contents.toString().split('\n');
        const nameLine = lines.find(line => line.startsWith('NAME='));
        if (nameLine)
            return nameLine.split('=')[1].replace(/"/g, '');
    } catch (e) {
        logError(e, 'pumice-welcome: could not read /etc/os-release');
    }
    return 'this system';
}

class WelcomeWindow extends Adw.ApplicationWindow {
    static {
        GObject.registerClass(this);

        this.add_shortcut(new Gtk.Shortcut({
            trigger: Gtk.ShortcutTrigger.parse_string('Escape'),
            action: Gtk.NamedAction.new('window.close'),
        }));

        this.install_action('window.install-os', null,
            self => self._launchInstaller());
    }

    constructor(application, osName) {
        const title = _('Welcome to %s').replace('%s', osName);
        super({
            application,
            title,
            content: new Gtk.WindowHandle(),
            default_width: 600,
            default_height: 550,
        });

        const statusPage = new Adw.StatusPage({
            title,
            iconName: 'system-software-install',
            description: _('This live media can be used to install %s or as a temporary system. Installation can be started at any time by launching the Install to Hard Drive app.').replace('%s', osName),
        });
        this.content.set_child(statusPage);

        const buttonBox = new Gtk.Box({
            orientation: Gtk.Orientation.HORIZONTAL,
            homogeneous: true,
            spacing: 24,
            halign: Gtk.Align.CENTER,
        });
        statusPage.set_child(buttonBox);

        const installButton = new Gtk.Button({
            label: _('Install %s…').replace('%s', osName),
            actionName: 'window.install-os',
        });
        installButton.add_css_class('pill');
        installButton.add_css_class('suggested-action');
        buttonBox.append(installButton);

        const notNowButton = new Gtk.Button({
            label: _('Not Now'),
            actionName: 'window.close',
        });
        notNowButton.add_css_class('pill');
        buttonBox.append(notNowButton);
    }

    _launchInstaller() {
        try {
            const subprocess = Gio.Subprocess.new(
                [LIVEINST_BIN],
                Gio.SubprocessFlags.NONE
            );
            subprocess.wait_async(null, null);
        } catch (e) {
            logError(e, `pumice-welcome: failed to launch ${LIVEINST_BIN}`);
        }
        this.close();
    }
}

class WelcomeApp extends Adw.Application {
    static {
        GObject.registerClass(this);
    }

    constructor() {
        super({application_id: 'org.pumice.welcome-screen'});
    }

    vfunc_activate() {
        let {activeWindow} = this;
        if (!activeWindow)
            activeWindow = new WelcomeWindow(this, getOsName());
        activeWindow.present();
    }
}

Gettext.textdomain('pumice-welcome');

if (!Gio.File.new_for_path(LIVEINST_BIN).query_exists(null)) {
    // No live installer on this system (e.g. an already-installed system
    // that still has this autostart entry from a stale home dir) -- do
    // nothing rather than show a popup with a dead Install button.
    print(`pumice-welcome: ${LIVEINST_BIN} not found, exiting quietly`);
} else {
    new WelcomeApp().run([programInvocationName, ...programArgs]);
}
