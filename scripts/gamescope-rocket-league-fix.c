#define _POSIX_C_SOURCE 200809L

#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <ctype.h>
#include <dirent.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static volatile sig_atomic_t running = 1;

static void stop_running(int signal_number) {
    (void)signal_number;
    running = 0;
}

static unsigned long find_host_pid(unsigned long namespace_pid) {
    DIR *proc = opendir("/proc");
    if (!proc)
        return 0;

    unsigned long host_pid = 0;
    struct dirent *entry;
    while ((entry = readdir(proc))) {
        if (!isdigit((unsigned char)entry->d_name[0]))
            continue;

        char path[512];
        snprintf(path, sizeof(path), "/proc/%s/cmdline", entry->d_name);
        FILE *cmdline = fopen(path, "r");
        if (!cmdline)
            continue;

        char command[4096] = {0};
        size_t length = fread(command, 1, sizeof(command) - 1, cmdline);
        fclose(cmdline);
        for (size_t i = 0; i < length; ++i) {
            if (!command[i])
                command[i] = ' ';
        }
        if (!strstr(command, "RocketLeague.exe"))
            continue;

        snprintf(path, sizeof(path), "/proc/%s/status", entry->d_name);
        FILE *status = fopen(path, "r");
        if (!status)
            continue;

        char line[512];
        while (fgets(line, sizeof(line), status)) {
            if (strncmp(line, "NSpid:", 6))
                continue;

            char *number = line + 6;
            unsigned long last_pid = 0;
            while (*number) {
                char *end;
                unsigned long pid = strtoul(number, &end, 10);
                if (end == number) {
                    ++number;
                    continue;
                }
                last_pid = pid;
                number = end;
            }
            if (last_pid == namespace_pid)
                host_pid = strtoul(entry->d_name, NULL, 10);
            break;
        }
        fclose(status);
        if (host_pid)
            break;
    }

    closedir(proc);
    return host_pid;
}

static void fix_windows(Display *display, Window window, Atom steam_game,
                        Atom net_wm_pid) {
    XClassHint class_hint = {0};

    if (XGetClassHint(display, window, &class_hint)) {
        if ((class_hint.res_name && !strcmp(class_hint.res_name, "steam_app_252950")) ||
            (class_hint.res_class && !strcmp(class_hint.res_class, "steam_app_252950"))) {
            unsigned long shortcut_id = 3450285581UL;
            XChangeProperty(display, window, steam_game, XA_CARDINAL, 32,
                            PropModeReplace, (unsigned char *)&shortcut_id, 1);

            Atom actual_type;
            int actual_format;
            unsigned long item_count;
            unsigned long bytes_after;
            unsigned char *pid_data = NULL;
            if (XGetWindowProperty(display, window, net_wm_pid, 0, 1, False,
                                   XA_CARDINAL, &actual_type, &actual_format,
                                   &item_count, &bytes_after, &pid_data) == Success &&
                actual_type == XA_CARDINAL && actual_format == 32 && item_count == 1) {
                unsigned long host_pid = find_host_pid(*(unsigned long *)pid_data);
                if (host_pid)
                    XChangeProperty(display, window, net_wm_pid, XA_CARDINAL, 32,
                                    PropModeReplace, (unsigned char *)&host_pid, 1);
            }
            if (pid_data)
                XFree(pid_data);

            XWindowAttributes attributes;
            if (XGetWindowAttributes(display, window, &attributes) &&
                attributes.map_state == IsViewable) {
                XWMHints *wm_hints = XGetWMHints(display, window);
                if (wm_hints) {
                    wm_hints->flags |= InputHint;
                    wm_hints->input = True;
                    XSetWMHints(display, window, wm_hints);
                    XFree(wm_hints);
                }
                XSetInputFocus(display, window, RevertToParent, CurrentTime);
            }
        }
        if (class_hint.res_name)
            XFree(class_hint.res_name);
        if (class_hint.res_class)
            XFree(class_hint.res_class);
    }

    Window root;
    Window parent;
    Window *children = NULL;
    unsigned int child_count = 0;
    if (XQueryTree(display, window, &root, &parent, &children, &child_count)) {
        for (unsigned int i = 0; i < child_count; ++i)
            fix_windows(display, children[i], steam_game, net_wm_pid);
    }
    if (children)
        XFree(children);
}

int main(void) {
    Display *display = XOpenDisplay(NULL);
    if (!display)
        return 1;

    signal(SIGINT, stop_running);
    signal(SIGTERM, stop_running);

    Atom steam_game = XInternAtom(display, "STEAM_GAME", False);
    Atom net_wm_pid = XInternAtom(display, "_NET_WM_PID", False);
    Window root = DefaultRootWindow(display);
    struct timespec interval = {.tv_sec = 0, .tv_nsec = 250000000L};

    while (running) {
        fix_windows(display, root, steam_game, net_wm_pid);
        XFlush(display);
        nanosleep(&interval, NULL);
    }

    XCloseDisplay(display);
    return 0;
}
