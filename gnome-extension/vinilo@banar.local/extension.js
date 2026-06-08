import GObject from 'gi://GObject';
import St from 'gi://St';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Clutter from 'gi://Clutter';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

// Resolver fish de forma portable (PATH primero, luego rutas comunes)
const FISH = GLib.find_program_in_path('fish') ?? '/usr/bin/fish';

const ViniloIndicator = GObject.registerClass(
class ViniloIndicator extends PanelMenu.Button {
    _init(extension) {
        // tercer arg = dontCreateMenu: queremos un toggle, no un menu
        super._init(0.0, 'Vinilo', true);
        this._cancellable = new Gio.Cancellable();
        this._active = false;

        const iconsDir = extension.dir.get_child('icons');
        this._iconIdle = Gio.icon_new_for_string(
            iconsDir.get_child('vinyl-symbolic.svg').get_path());
        this._iconPlay = Gio.icon_new_for_string(
            iconsDir.get_child('vinyl-playing-symbolic.svg').get_path());

        this._icon = new St.Icon({
            gicon: this._iconIdle,
            style_class: 'system-status-icon',
        });
        this.add_child(this._icon);

        this.connect('button-press-event', () => {
            this._toggle();
            return Clutter.EVENT_STOP;
        });
        this.connect('touch-event', (_actor, event) => {
            if (event.type() === Clutter.EventType.TOUCH_BEGIN) {
                this._toggle();
                return Clutter.EVENT_STOP;
            }
            return Clutter.EVENT_PROPAGATE;
        });

        // Reflejar el estado real al arrancar (por si el link ya esta puesto)
        this._refreshState();
    }

    _setActive(active) {
        this._active = active;
        this._icon.gicon = active ? this._iconPlay : this._iconIdle;
        if (active)
            this._icon.add_style_class_name('vinilo-active');
        else
            this._icon.remove_style_class_name('vinilo-active');
    }

    _toggle() {
        const fn = this._active ? 'vinilo-off' : 'vinilo-on';
        // Flip optimista para que el icono responda al toque
        this._setActive(!this._active);
        try {
            const proc = Gio.Subprocess.new(
                [FISH, '-c', fn],
                Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_SILENCE);
            proc.wait_async(this._cancellable, () => this._refreshState());
        } catch (e) {
            logError(e, `vinilo: no se pudo ejecutar ${fn}`);
            this._refreshState();
        }
    }

    _refreshState() {
        try {
            const proc = Gio.Subprocess.new(
                [FISH, '-c', 'vinilo-status'],
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE);
            proc.communicate_utf8_async(null, this._cancellable, (p, res) => {
                try {
                    const [, stdout] = p.communicate_utf8_finish(res);
                    this._setActive(stdout.trim() === 'on');
                } catch (_e) {
                    // cancelado o error: no tocar el estado
                }
            });
        } catch (_e) {
            // ignorar
        }
    }

    destroy() {
        if (this._cancellable) {
            this._cancellable.cancel();
            this._cancellable = null;
        }
        super.destroy();
    }
});

export default class ViniloExtension extends Extension {
    enable() {
        this._indicator = new ViniloIndicator(this);
        Main.panel.addToStatusArea('vinilo-indicator', this._indicator, 0, 'right');
    }

    disable() {
        this._indicator?.destroy();
        this._indicator = null;
    }
}
