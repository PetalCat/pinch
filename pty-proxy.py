#!/usr/bin/env python3
"""PTY proxy: spawns command in a real PTY, pipes stdin<->PTY->stdout.
Supports RESIZE cols rows commands on stdin."""
import os, pty, select, signal, struct, fcntl, termios, sys

def main():
    if len(sys.argv) < 4:
        sys.exit(1)

    cols, rows = int(sys.argv[1]), int(sys.argv[2])
    cmd = sys.argv[3:]

    master, slave = pty.openpty()
    fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack('HHHH', rows, cols, 0, 0))

    env = os.environ.copy()
    env['TERM'] = 'xterm-256color'
    env['COLORTERM'] = 'truecolor'

    pid = os.fork()
    if pid == 0:
        os.setsid()
        os.close(master)
        fcntl.ioctl(slave, termios.TIOCSCTTY, 0)
        os.dup2(slave, 0); os.dup2(slave, 1); os.dup2(slave, 2)
        if slave > 2: os.close(slave)
        os.execvpe(cmd[0], cmd, env)
    else:
        os.close(slave)
        stdin_fd = 0
        alive = True

        try:
            while alive:
                fds = [master, stdin_fd]
                rlist, _, _ = select.select(fds, [], [], 0.1)

                if master in rlist:
                    try:
                        data = os.read(master, 32768)
                        if not data:
                            alive = False
                            break
                        os.write(1, data)
                    except OSError:
                        alive = False
                        break

                if stdin_fd in rlist:
                    try:
                        data = os.read(stdin_fd, 32768)
                        if not data:
                            # stdin closed — don't exit, child may still be running
                            fds = [master]
                            continue
                        text = data.decode('utf-8', errors='replace')
                        # Check for RESIZE command
                        if text.startswith('RESIZE ') and '\n' in text:
                            line = text.split('\n')[0]
                            parts = line.split()
                            if len(parts) == 3:
                                try:
                                    c, r = int(parts[1]), int(parts[2])
                                    fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack('HHHH', r, c, 0, 0))
                                    os.kill(pid, signal.SIGWINCH)
                                except (ValueError, OSError):
                                    pass
                            # Pass through any remaining data after the RESIZE line
                            rest = '\n'.join(text.split('\n')[1:])
                            if rest:
                                os.write(master, rest.encode())
                        else:
                            os.write(master, data)
                    except OSError:
                        pass

                # Check child
                try:
                    wpid, status = os.waitpid(pid, os.WNOHANG)
                    if wpid != 0:
                        # Drain remaining output
                        while True:
                            r, _, _ = select.select([master], [], [], 0.2)
                            if not r: break
                            try:
                                d = os.read(master, 32768)
                                if not d: break
                                os.write(1, d)
                            except OSError: break
                        alive = False
                except ChildProcessError:
                    alive = False

        except KeyboardInterrupt:
            pass
        finally:
            os.close(master)
            try: os.kill(pid, signal.SIGTERM)
            except ProcessLookupError: pass

if __name__ == '__main__':
    main()
