#!/usr/bin/env python3
"""
Generate portfolio-ready HTML content from OpenResponses documentation.
NO EXTERNAL DEPENDENCIES - uses only Python standard library.
"""

import os
import re
import json
import html
from datetime import datetime

OUTPUT_DIR = "_portfolio_output"


def read_file_safe(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        print(f"  ⚠️  File not found: {path}")
        return ""


def extract_status_from_roadmap(content):
    status = {"phase": "Phase 1 Complete", "last_updated": "2025-11-07"}
    match = re.search(r"\*\*\[(\d{4}-\d{2}-\d{2})\] Status Snapshot:\*\*", content)
    if match:
        status["last_updated"] = match.group(1)
    return status


def extract_features_from_readme(content):
    features = []
    match = re.search(r"## Core Features\n\n(.*?)(?=\n---|\n## )", content, re.DOTALL)
    if match:
        for line in match.group(1).split("\n"):
            feat = re.match(r"- \*\*([^*]+)\*\*:?\s*(.+)?", line)
            if feat:
                features.append(
                    {"name": feat.group(1), "description": feat.group(2) or ""}
                )
    return features


def extract_api_coverage(content):
    coverage = []
    in_table = False
    for line in content.split("\n"):
        if "| API Feature Category" in line:
            in_table = True
            continue
        if in_table:
            if line.startswith("|") and "---" not in line:
                parts = [p.strip() for p in line.split("|")[1:-1]]
                if len(parts) >= 3 and parts[0]:
                    status = (
                        "complete"
                        if "✅" in parts[1]
                        else "partial" if "🟡" in parts[1] else "pending"
                    )
                    coverage.append(
                        {
                            "feature": parts[0].replace("**", ""),
                            "status": status,
                            "details": parts[2][:80],
                        }
                    )
            elif not line.startswith("|"):
                break
    return coverage


def generate_index_html(status, features, coverage):
    feature_cards = ""
    for f in features[:6]:
        feature_cards += f"""
        <div class="feature-card">
            <h3>{html.escape(f["name"])}</h3>
            <p>{html.escape(f["description"])}</p>
        </div>"""

    coverage_rows = ""
    for c in coverage[:10]:
        icon = (
            "✅"
            if c["status"] == "complete"
            else "🟡" if c["status"] == "partial" else "❌"
        )
        coverage_rows += f"""
        <tr class="{c["status"]}">
            <td>{html.escape(c["feature"])}</td>
            <td>{icon}</td>
            <td>{html.escape(c["details"])}...</td>
        </tr>"""

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OpenResponses - Project Deep Dive | Gunnar Hostetler</title>
    <meta name="description" content="OpenResponses: SwiftUI iOS client for OpenAI Responses API.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <nav class="project-nav">
        <a href="../../index.html" class="back-link"><i class="fas fa-arrow-left"></i> Portfolio</a>
        <div class="nav-links">
            <a href="#overview">Overview</a>
            <a href="#features">Features</a>
            <a href="#api">API</a>
            <a href="#roadmap">Roadmap</a>
            <a href="https://github.com/Gunnarguy/OpenResponses" target="_blank"><i class="fab fa-github"></i></a>
        </div>
    </nav>

    <header class="project-hero">
        <div class="container">
            <div class="hero-badge">
                <span class="status-badge">{html.escape(status["phase"])}</span>
                <span class="date-badge">Updated: {html.escape(status["last_updated"])}</span>
            </div>
            <h1>OpenResponses</h1>
            <p class="hero-subtitle">SwiftUI-powered AI assistant for OpenAI Responses API with computer use, code interpreter, file search, and MCP integrations.</p>
            <div class="hero-actions">
                <a href="https://github.com/Gunnarguy/OpenResponses" class="btn btn-primary" target="_blank">
                    <i class="fab fa-github"></i> View on GitHub
                </a>
            </div>
        </div>
    </header>

    <section id="overview" class="section">
        <div class="container">
            <h2>Project Overview</h2>
            <div class="overview-grid">
                <div class="overview-card"><i class="fas fa-mobile-alt"></i><h3>iOS Native</h3><p>SwiftUI, iOS 17+, Catalyst for macOS.</p></div>
                <div class="overview-card"><i class="fas fa-shield-alt"></i><h3>Production Ready</h3><p>Keychain storage, approval flows, safety rails.</p></div>
                <div class="overview-card"><i class="fas fa-plug"></i><h3>Full API Coverage</h3><p>All Responses API tools and streaming events.</p></div>
                <div class="overview-card"><i class="fas fa-eye"></i><h3>Deep Observability</h3><p>Analytics, reasoning traces, token tracking.</p></div>
            </div>
        </div>
    </section>

    <section id="features" class="section section-alt">
        <div class="container">
            <h2>Core Features</h2>
            <div class="features-grid">{feature_cards}</div>
        </div>
    </section>

    <section id="api" class="section">
        <div class="container">
            <h2>API Implementation</h2>
            <table class="api-table">
                <thead><tr><th>Feature</th><th>Status</th><th>Details</th></tr></thead>
                <tbody>{coverage_rows}</tbody>
            </table>
        </div>
    </section>

    <section id="roadmap" class="section section-alt">
        <div class="container">
            <h2>Roadmap</h2>
            <div class="roadmap-timeline">
                <div class="roadmap-item completed"><div class="roadmap-marker"></div><div class="roadmap-content"><h3>Phase 1: Core</h3><span class="status">✅ Complete</span><p>Full API tools, streaming, computer use, MCP.</p></div></div>
                <div class="roadmap-item active"><div class="roadmap-marker"></div><div class="roadmap-content"><h3>Phase 2: Conversations API</h3><span class="status">🚧 In Progress</span><p>Backend sync, cross-device conversations.</p></div></div>
                <div class="roadmap-item"><div class="roadmap-marker"></div><div class="roadmap-content"><h3>Phase 3: Polish</h3><span class="status">📋 Planned</span><p>Apple integrations, accessibility.</p></div></div>
            </div>
        </div>
    </section>

    <footer class="project-footer">
        <p>Auto-synced from <a href="https://github.com/Gunnarguy/OpenResponses">OpenResponses</a></p>
        <p class="sync-time">Last sync: {datetime.now().strftime("%Y-%m-%d %H:%M")}</p>
    </footer>
</body>
</html>"""


def generate_styles():
    return """:root {
    --bg-primary: #0a0a0f; --bg-secondary: #12121a; --bg-card: #1a1a24;
    --text-primary: #fff; --text-secondary: #a0a0b0;
    --accent-primary: #6366f1; --accent-secondary: #818cf8; --accent-green: #22c55e;
    --border-color: #2a2a3a;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Inter', sans-serif; background: var(--bg-primary); color: var(--text-primary); line-height: 1.6; }
.container { max-width: 1200px; margin: 0 auto; padding: 0 2rem; }
.project-nav { position: fixed; top: 0; left: 0; right: 0; background: rgba(10,10,15,0.95); backdrop-filter: blur(10px); padding: 1rem 2rem; display: flex; justify-content: space-between; align-items: center; z-index: 1000; border-bottom: 1px solid var(--border-color); }
.back-link { color: var(--text-secondary); text-decoration: none; display: flex; align-items: center; gap: 0.5rem; }
.back-link:hover { color: var(--accent-primary); }
.nav-links { display: flex; gap: 1.5rem; }
.nav-links a { color: var(--text-secondary); text-decoration: none; font-size: 0.9rem; }
.nav-links a:hover { color: var(--accent-primary); }
.project-hero { padding: 8rem 0 4rem; background: linear-gradient(180deg, var(--bg-secondary), var(--bg-primary)); text-align: center; }
.hero-badge { display: flex; justify-content: center; gap: 1rem; margin-bottom: 1.5rem; }
.status-badge { padding: 0.5rem 1rem; border-radius: 9999px; font-size: 0.85rem; background: var(--accent-green); color: #000; }
.date-badge { padding: 0.5rem 1rem; border-radius: 9999px; font-size: 0.85rem; background: var(--bg-card); color: var(--text-secondary); border: 1px solid var(--border-color); }
.project-hero h1 { font-size: 3.5rem; font-weight: 800; margin-bottom: 1rem; background: linear-gradient(135deg, #fff, var(--accent-secondary)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
.hero-subtitle { font-size: 1.25rem; color: var(--text-secondary); max-width: 700px; margin: 0 auto 2rem; }
.hero-actions { display: flex; justify-content: center; gap: 1rem; }
.btn { display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.75rem 1.5rem; border-radius: 8px; text-decoration: none; font-weight: 500; }
.btn-primary { background: var(--accent-primary); color: white; }
.btn-primary:hover { background: var(--accent-secondary); }
.section { padding: 5rem 0; }
.section-alt { background: var(--bg-secondary); }
.section h2 { font-size: 2rem; margin-bottom: 2rem; text-align: center; }
.overview-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; }
.overview-card { background: var(--bg-card); padding: 2rem; border-radius: 12px; border: 1px solid var(--border-color); text-align: center; }
.overview-card i { font-size: 2.5rem; color: var(--accent-primary); margin-bottom: 1rem; display: block; }
.overview-card h3 { margin-bottom: 0.5rem; }
.overview-card p { color: var(--text-secondary); font-size: 0.95rem; }
.features-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.5rem; }
.feature-card { background: var(--bg-card); padding: 1.5rem; border-radius: 12px; border: 1px solid var(--border-color); }
.feature-card:hover { border-color: var(--accent-primary); }
.feature-card h3 { color: var(--accent-secondary); margin-bottom: 0.5rem; }
.feature-card p { color: var(--text-secondary); font-size: 0.95rem; }
.api-table { width: 100%; border-collapse: collapse; background: var(--bg-card); border-radius: 12px; overflow: hidden; }
.api-table th, .api-table td { padding: 1rem; text-align: left; border-bottom: 1px solid var(--border-color); }
.api-table th { background: var(--bg-secondary); }
.api-table tr.complete td:first-child { border-left: 3px solid var(--accent-green); }
.api-table tr.partial td:first-child { border-left: 3px solid #eab308; }
.roadmap-timeline { max-width: 700px; margin: 0 auto; }
.roadmap-item { display: flex; gap: 1.5rem; padding: 1.5rem 0; position: relative; }
.roadmap-item:not(:last-child)::after { content: ''; position: absolute; left: 11px; top: 3.5rem; bottom: 0; width: 2px; background: var(--border-color); }
.roadmap-marker { width: 24px; height: 24px; border-radius: 50%; background: var(--border-color); flex-shrink: 0; }
.roadmap-item.completed .roadmap-marker { background: var(--accent-green); }
.roadmap-item.active .roadmap-marker { background: var(--accent-primary); box-shadow: 0 0 0 4px rgba(99,102,241,0.3); }
.roadmap-content h3 { margin-bottom: 0.25rem; }
.roadmap-content .status { font-size: 0.85rem; color: var(--text-secondary); display: block; margin-bottom: 0.5rem; }
.roadmap-content p { color: var(--text-secondary); }
.project-footer { padding: 2rem 0; text-align: center; border-top: 1px solid var(--border-color); }
.project-footer a { color: var(--accent-primary); text-decoration: none; }
.sync-time { font-size: 0.85rem; color: var(--text-secondary); margin-top: 0.5rem; }
@media (max-width: 768px) { .project-hero h1 { font-size: 2.5rem; } .nav-links { display: none; } }
"""


def main():
    print("🚀 Generating portfolio content...")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(f"{OUTPUT_DIR}/docs", exist_ok=True)

    readme = read_file_safe("README.md")
    roadmap = read_file_safe("docs/ROADMAP.md")

    status = extract_status_from_roadmap(roadmap)
    features = extract_features_from_readme(readme)
    coverage = extract_api_coverage(roadmap)

    print(f"  ✓ Found {len(features)} features, {len(coverage)} API items")

    with open(f"{OUTPUT_DIR}/index.html", "w") as f:
        f.write(generate_index_html(status, features, coverage))
    print("  ✓ Generated index.html")

    with open(f"{OUTPUT_DIR}/styles.css", "w") as f:
        f.write(generate_styles())
    print("  ✓ Generated styles.css")

    for src in ["README.md", "docs/ROADMAP.md", "docs/Tools.md", "PRIVACY.md"]:
        content = read_file_safe(src)
        if content:
            with open(f"{OUTPUT_DIR}/docs/{os.path.basename(src)}", "w") as f:
                f.write(content)
    print("  ✓ Copied markdown docs")

    with open(f"{OUTPUT_DIR}/manifest.json", "w") as f:
        json.dump(
            {
                "generated_at": datetime.now().isoformat(),
                "source": "Gunnarguy/OpenResponses",
            },
            f,
        )

    print(f"\n✅ Done! Output in {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
