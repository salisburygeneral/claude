package main

import (
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
)

const (
	image   = "ghcr.io/salisburygeneral/claude:latest"
	workdir = "/workspace"
	cpus    = "4"
	memory  = "4096M"
)

func main() {
	log.SetFlags(0)
	log.SetPrefix("claude-launcher: ")

	name := os.Getenv("CONTAINER_CLI")
	if name == "" {
		name = "container"
	}
	if name != "container" && name != "docker" {
		log.Fatalf("CONTAINER_CLI must be container or docker, got %q", name)
	}

	cli, err := exec.LookPath(name)
	if err != nil {
		log.Fatal(err)
	}

	pull := exec.Command(cli, "image", "pull", image)
	pull.Stdout = os.Stderr
	pull.Stderr = os.Stderr
	if err := pull.Run(); err != nil {
		log.Printf("pull failed (%v), using the local image", err)
	}

	cwd, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}

	credsDir, err := os.MkdirTemp("", "claude-launcher-credentials-")
	if err != nil {
		log.Fatal(err)
	}

	creds, err := exec.Command("security", "find-generic-password",
		"-s", "Claude Code-credentials", "-w").Output()
	if err != nil {
		log.Printf("not copying credentials: %v", err)
	}
	credsFile := filepath.Join(credsDir, ".credentials.json")
	if err := os.WriteFile(credsFile, creds, 0o600); err != nil {
		log.Fatal(err)
	}

	argv := []string{name, "run", "--rm", "-i", "-t",
		"--cpus", cpus,
		"--memory", memory,
		"-v", cwd + ":" + workdir,
		"-v", credsFile + ":/home/claude/.claude/.credentials.json",
		"-w", workdir,
		image,
	}
	argv = append(argv, os.Args[1:]...)

	if err := os.Setenv("HERDR_AGENT", "claude"); err != nil {
		log.Fatal(err)
	}

	if err := syscall.Exec(cli, argv, os.Environ()); err != nil {
		log.Fatal(err)
	}
}
