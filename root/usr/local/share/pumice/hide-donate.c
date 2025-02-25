/*
 * hide-donate.c
 *
 * Hides the "Donate" row in gnome-control-center's About/System page.
 *
 * Depends:
 *   sudo dnf install gtk4-devel
 *   sudo dnf group install development-tools
 *
 * Build:
 *   gcc -shared -fPIC -o hide-donate.so hide-donate.c \
 *       $(pkg-config --cflags --libs gtk4) -ldl -Wl,--no-as-needed
 *
 * Runs using the dbus override in:
 *   ~/.local/share/dbus-1/services/org.gnome.Settings.service
 *
 * Test with:
 *   LD_PRELOAD=/usr/local/share/pumice/hide-donate.so gnome-control-center system about
 */

#define _GNU_SOURCE
#include <dlfcn.h>
#include <gtk/gtk.h>
#include <string.h>

#define PUMICE_SCAN_INTERVAL_MS 300

static void (*orig_gtk_window_present)(GtkWindow *) = NULL;

static gboolean
is_donate_button(GtkWidget *widget)
{
    if (!GTK_IS_BUTTON(widget))
        return FALSE;

    const char *label = gtk_button_get_label(GTK_BUTTON(widget));
    if (!label) {
        GtkWidget *child = gtk_button_get_child(GTK_BUTTON(widget));
        if (GTK_IS_LABEL(child))
            label = gtk_label_get_text(GTK_LABEL(child));
    }

    return label && strstr(label, "onate");
}

static gboolean
walk_and_hide(GtkWidget *widget)
{
    if (is_donate_button(widget)) {
        GtkWidget *row = widget;
        while (row && !GTK_IS_LIST_BOX_ROW(row))
            row = gtk_widget_get_parent(row);

        if (row) {
            GtkWidget *listbox = gtk_widget_get_parent(row);
            GtkWidget *group   = listbox ? gtk_widget_get_parent(listbox) : NULL;

            gboolean has_siblings = FALSE;
            if (listbox)
                for (GtkWidget *s = gtk_widget_get_first_child(listbox); s; s = gtk_widget_get_next_sibling(s))
                    if (s != row) { has_siblings = TRUE; break; }

            gtk_widget_unparent(row);

            if (!has_siblings && group)
                gtk_widget_unparent(group);
        }
        return TRUE;
    }

    for (GtkWidget *child = gtk_widget_get_first_child(widget);
         child; child = gtk_widget_get_next_sibling(child))
        if (walk_and_hide(child))
            return TRUE;

    return FALSE;
}

static gboolean
scan_window(gpointer window)
{
    if (!GTK_IS_WINDOW(window))
        return G_SOURCE_REMOVE;               /* window gone — stop */

    walk_and_hide(GTK_WIDGET(window));
    return G_SOURCE_CONTINUE;
}

static void
start_scanner(GtkWidget *window)
{
    if (GPOINTER_TO_UINT(g_object_get_data(G_OBJECT(window), "pumice-timer")) != 0)
        return;                               /* already running */

    guint id = g_timeout_add(PUMICE_SCAN_INTERVAL_MS, scan_window, window);
    g_object_set_data(G_OBJECT(window), "pumice-timer", GUINT_TO_POINTER(id));
}

static void
stop_scanner(GtkWidget *window)
{
    guint id = GPOINTER_TO_UINT(g_object_get_data(G_OBJECT(window), "pumice-timer"));
    if (id != 0) {
        g_source_remove(id);
        g_object_set_data(G_OBJECT(window), "pumice-timer", GUINT_TO_POINTER(0));
    }
}

static void on_map(GtkWidget *window, gpointer u)   { (void)u; start_scanner(window); }
static void on_unmap(GtkWidget *window, gpointer u) { (void)u; stop_scanner(window); }

void
gtk_window_present(GtkWindow *window)
{
    orig_gtk_window_present(window);

    GtkWidget *w = GTK_WIDGET(window);

    if (GPOINTER_TO_UINT(g_object_get_data(G_OBJECT(w), "pumice-hooked")) == 0) {
        g_object_set_data(G_OBJECT(w), "pumice-hooked", GUINT_TO_POINTER(1));
        g_signal_connect(w, "map",   G_CALLBACK(on_map),   NULL);
        g_signal_connect(w, "unmap", G_CALLBACK(on_unmap), NULL);
    }

    if (gtk_widget_get_mapped(w))
        start_scanner(w);
}

__attribute__((constructor))
static void init(void)
{
    orig_gtk_window_present = dlsym(RTLD_NEXT, "gtk_window_present");
}
