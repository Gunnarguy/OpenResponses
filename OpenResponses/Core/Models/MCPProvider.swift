import Foundation

struct MCPProvider: Identifiable, Hashable {
    enum Category: String, CaseIterable { case productivity = "Productivity", design = "Design", development = "Development", data = "Data", cloud = "Cloud", communication = "Communication", files = "Files", commerce = "Commerce" }
    enum SignIn: String { case oauth, publicAccess, providerSetup, automatic }
    let id: String
    let name: String
    let summary: String
    let category: Category
    let serverURL: String
    var signIn: SignIn = .oauth
    var documentationURL: String?
    var registryName: String?
    var icon: String {
        switch category {
        case .productivity: "checklist"
        case .design: "paintpalette"
        case .development: "curlybraces"
        case .data: "externaldrive"
        case .cloud: "cloud"
        case .communication: "bubble.left.and.bubble.right"
        case .files: "folder"
        case .commerce: "creditcard"
        }
    }
    var host: String { URL(string: serverURL)?.host ?? "OpenAI connector" }
    var signInLabel: String {
        switch signIn {
        case .oauth: "Account sign-in"
        case .publicAccess: "No account needed"
        case .providerSetup: "Provider setup required"
        case .automatic: "Sign-in checked when connecting"
        }
    }

    static let featured: [MCPProvider] = [
        .init(id: "notion", name: "Notion", summary: "Search and work with workspace pages and databases.", category: .productivity, serverURL: "https://mcp.notion.com/mcp", documentationURL: "https://developers.notion.com/guides/mcp/build-mcp-client"),
        .init(id: "linear", name: "Linear", summary: "Work with issues, projects, teams, and planning.", category: .productivity, serverURL: "https://mcp.linear.app/mcp", documentationURL: "https://linear.app/docs/mcp"),
        .init(id: "atlassian", name: "Atlassian", summary: "Bring Jira and Confluence into your conversations.", category: .productivity, serverURL: "https://mcp.atlassian.com/v1/mcp", documentationURL: "https://support.atlassian.com/atlassian-rovo-mcp-server/"),
        .init(id: "canva", name: "Canva", summary: "Find, create, and export designs.", category: .design, serverURL: "https://mcp.canva.com/mcp", documentationURL: "https://www.canva.dev/docs/mcp/"),
        .init(id: "figma", name: "Figma", summary: "Bring design context from Figma files into chat.", category: .design, serverURL: "https://mcp.figma.com/mcp", signIn: .providerSetup, documentationURL: "https://developers.figma.com/docs/figma-mcp-server/remote-server-installation/"),
        .init(id: "asana", name: "Asana", summary: "Tasks, projects, portfolios, and the Asana Work Graph.", category: .productivity, serverURL: "https://mcp.asana.com/v2/mcp", signIn: .providerSetup, documentationURL: "https://developers.asana.com/docs/connecting-mcp-clients-to-asanas-v2-server"),
        .init(id: "monday", name: "monday.com", summary: "Manage boards, items, and team workflows.", category: .productivity, serverURL: "https://mcp.monday.com/mcp", signIn: .providerSetup, registryName: "com.monday/monday.com"),
        .init(id: "todoist", name: "Todoist", summary: "Organize tasks and projects.", category: .productivity, serverURL: "https://ai.todoist.net/mcp", registryName: "net.todoist/mcp"),
        .init(id: "miro", name: "Miro", summary: "Explore boards and collaborate on visual ideas.", category: .design, serverURL: "https://mcp.miro.com/", documentationURL: "https://developers.miro.com/docs/connecting-to-miro-mcp"),
        .init(id: "airtable", name: "Airtable", summary: "Explore bases, tables, and records.", category: .data, serverURL: "https://mcp.airtable.com/mcp", signIn: .providerSetup, registryName: "com.airtable/mcp"),
        .init(id: "stripe", name: "Stripe", summary: "Work with payments, customers, and Stripe resources.", category: .commerce, serverURL: "https://mcp.stripe.com", registryName: "com.stripe/mcp"),
        .init(id: "paypal", name: "PayPal", summary: "Connect payment and business tools.", category: .commerce, serverURL: "https://mcp.paypal.com/mcp", registryName: "com.paypal.mcp/mcp"),
        .init(id: "intercom", name: "Intercom", summary: "Search conversations, contacts, and help content.", category: .communication, serverURL: "https://mcp.intercom.com/mcp", signIn: .providerSetup, documentationURL: "https://developers.intercom.com/docs/guides/mcp"),
        .init(id: "hubspot", name: "HubSpot", summary: "Connect CRM data and customer workflows.", category: .commerce, serverURL: "https://mcp.hubspot.com", signIn: .providerSetup, documentationURL: "https://developers.hubspot.com/docs/apps/developer-platform/build-apps/integrate-with-the-remote-hubspot-mcp-server"),
        .init(id: "box", name: "Box", summary: "Search and work with enterprise files.", category: .files, serverURL: "https://mcp.box.com", signIn: .providerSetup, documentationURL: "https://developer.box.com/guides/box-mcp/setup"),
        .init(id: "slack", name: "Slack", summary: "Bring workspace conversations into your work.", category: .communication, serverURL: "https://mcp.slack.com/mcp", signIn: .providerSetup, documentationURL: "https://docs.slack.dev/ai/slack-mcp-server"),
        .init(id: "webflow", name: "Webflow", summary: "Work with sites and CMS content.", category: .design, serverURL: "https://mcp.webflow.com/mcp", registryName: "com.webflow/mcp"),
        .init(id: "vercel", name: "Vercel", summary: "Inspect projects and deployments.", category: .cloud, serverURL: "https://mcp.vercel.com", signIn: .providerSetup, registryName: "com.vercel/vercel-mcp"),
        .init(id: "supabase", name: "Supabase", summary: "Explore projects, databases, and development tools.", category: .data, serverURL: "https://mcp.supabase.com/mcp", documentationURL: "https://supabase.com/docs/guides/getting-started/mcp"),
        .init(id: "neon", name: "Neon", summary: "Work with Postgres projects and development branches.", category: .data, serverURL: "https://mcp.neon.tech/mcp", documentationURL: "https://neon.com/docs/ai/neon-mcp-server"),
        .init(id: "posthog", name: "PostHog", summary: "Explore product analytics and experiments.", category: .development, serverURL: "https://mcp.posthog.com/mcp", registryName: "io.github.PostHog/mcp"),
        .init(id: "sentry", name: "Sentry", summary: "Investigate errors, performance, and project issues.", category: .development, serverURL: "https://mcp.sentry.dev/mcp", documentationURL: "https://mcp.sentry.dev/"),
        .init(id: "amplitude", name: "Amplitude", summary: "Work with product analytics and insights.", category: .development, serverURL: "https://mcp.amplitude.com/mcp", registryName: "com.amplitude/mcp-server"),
        .init(id: "deepwiki", name: "DeepWiki", summary: "Ask questions about public code repositories.", category: .development, serverURL: "https://mcp.deepwiki.com/mcp", signIn: .publicAccess, documentationURL: "https://docs.devin.ai/work-with-devin/deepwiki-mcp"),
        .init(id: "cloudflare-bindings", name: "Cloudflare Workers", summary: "Work with Worker bindings and resources.", category: .cloud, serverURL: "https://bindings.mcp.cloudflare.com/mcp", registryName: "com.cloudflare.mcp/mcp"),
        .init(id: "cloudflare-observability", name: "Cloudflare Observability", summary: "Investigate application logs and metrics.", category: .cloud, serverURL: "https://observability.mcp.cloudflare.com/mcp", registryName: "com.cloudflare.mcp/mcp"),
        .init(id: "cloudflare-builds", name: "Cloudflare Builds", summary: "Inspect and manage Worker builds.", category: .cloud, serverURL: "https://builds.mcp.cloudflare.com/mcp", registryName: "com.cloudflare.mcp/mcp"),
        .init(id: "cloudflare-browser", name: "Cloudflare Browser Rendering", summary: "Use Cloudflare's remote browser tools.", category: .cloud, serverURL: "https://browser.mcp.cloudflare.com/mcp", registryName: "com.cloudflare.mcp/mcp"),
        .init(id: "cloudflare-radar", name: "Cloudflare Radar", summary: "Explore internet traffic and network insights.", category: .cloud, serverURL: "https://radar.mcp.cloudflare.com/mcp", registryName: "com.cloudflare.mcp/mcp"),
        .init(id: "cloudflare-docs", name: "Cloudflare Documentation", summary: "Search current Cloudflare documentation.", category: .development, serverURL: "https://docs.mcp.cloudflare.com/mcp", signIn: .publicAccess, registryName: "com.cloudflare.mcp/mcp"),
        .init(id: "zoom-workspace", name: "Zoom Workplace", summary: "Connect Zoom collaboration tools.", category: .communication, serverURL: "https://mcp.zoom.us/mcp/zoom/streamable", signIn: .providerSetup, registryName: "io.github.zoom/zoom-workspace"),
        .init(id: "zoom-meetings", name: "Zoom Meetings", summary: "Work with meeting information.", category: .communication, serverURL: "https://mcp.zoom.us/mcp/meeting/streamable", signIn: .providerSetup, registryName: "io.github.zoom/zoom-meetings"),
        .init(id: "zoom-docs", name: "Zoom Docs", summary: "Work with collaborative documents.", category: .files, serverURL: "https://mcp.zoom.us/mcp/docs/streamable", signIn: .providerSetup, registryName: "io.github.zoom/zoom-docs"),
        .init(id: "zoom-tasks", name: "Zoom Tasks", summary: "Organize tasks across Zoom workflows.", category: .productivity, serverURL: "https://mcp.zoom.us/mcp/tasks/streamable", signIn: .providerSetup, registryName: "io.github.zoom/zoom-tasks"),
        .init(id: "zoom-chat", name: "Zoom Team Chat", summary: "Connect team conversations.", category: .communication, serverURL: "https://mcp.zoom.us/mcp/chat/streamable", signIn: .providerSetup, registryName: "io.github.zoom/zoom-team-chat"),
        .init(id: "zoom-whiteboard", name: "Zoom Whiteboard", summary: "Work with collaborative whiteboards.", category: .design, serverURL: "https://mcp.zoom.us/mcp/whiteboard/streamable", signIn: .providerSetup, registryName: "io.github.zoom/zoom-whiteboard")
    ] + MCPConnector.library.map {
        MCPProvider(id: $0.id, name: $0.name, summary: $0.description,
            category: $0.category == .storage ? .files : $0.category == .productivity ? .productivity : .communication,
            serverURL: "", signIn: .providerSetup,
            documentationURL: "https://developers.openai.com/api/docs/guides/tools-connectors-mcp")
    }
}
