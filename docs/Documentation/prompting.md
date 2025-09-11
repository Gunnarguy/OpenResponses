Prompting
=========

Learn how to create prompts.

**Prompting** is the process of providing input to a model. The quality of your output often depends on how well you're able to prompt the model.

Overview
--------

Prompting is both an art and a science. OpenAI has some strategies and API design decisions to help you construct strong prompts and get consistently good results from a model. We encourage you to experiment.

### Prompts in the API

OpenAI provides a long-lived prompt object, with versioning and templating shared by all users in a project. This design lets you manage, test, and reuse prompts across your team, with one central definition across APIs, SDKs, and dashboard.

Universal prompt IDs give you flexibility to test and build. Variables and prompts share a base prompt, so when you create a new version, you can use that for [evals](/docs/guides/evals) and determine whether a prompt performs better or worse.

### Prompting tools and techniques

*   **[Prompt caching](/docs/guides/prompt-caching)**: Reduce latency by up to 80% and cost by up to 75%
*   **[Prompt engineering](/docs/guides/prompt-engineering)**: Learn strategies, techniques, and tools to construct prompts

Create a prompt
---------------

Log in and use the OpenAI [dashboard](https://platform.openai.com/chat) to create, save, version, and share your prompts.

1.  **Start a prompt**
    
    In the [Playground](/playground), fill out the fields to create your desired prompt.
    
      
    
2.  **Add prompt variables**
    
    Variables let you inject dynamic values without changing your prompt. Use them in any message role using `{{variable}}`. For example, when creating a local weather prompt, you might add a `city` variable with the value `San Francisco`.
    
      
    
3.  **Use the prompt in your [Responses API](/docs/guides/text?api-mode=responses) call**
    
    Find your prompt ID and version number in the URL, and pass it as `prompt_id`:
    
    ```bash
    curl -s -X POST "https://api.openai.com/v1/responses" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
        "prompt": {
        "prompt_id": "pmpt_123",
        "variables": {
            "city": "San Francisco"
        }
        }
    }'
    ```
    
4.  **Create a new prompt version**
    
    Versions let you iterate on your prompts without overwriting existing details. You can use all versions in the API and evaluate their performance against each other. The prompt ID points to the latest published version unless you specify a version.
    
    To create a new version, edit the prompt and click **Update**. You'll receive a new prompt ID to copy and use in your Responses API calls.
    
      
    
5.  **Roll back if needed**
    
    In the [prompts dashboard](/chat), select the prompt you want to roll back. On the right, click **History**. Find the version you want to restore, and click **Restore**.
    

Refine your prompt
------------------

*   Put overall tone or role guidance in the system message; keep task-specific details and examples in user messages.
*   Combine few-shot examples into a concise YAML-style or bulleted block so they’re easy to scan and update.
*   Mirror your project structure with clear folder names so teammates can locate prompts quickly.
*   Rerun your linked eval every time you publish—catching issues early is cheaper than fixing them in production.

Next steps
----------

When you feel confident in your prompts, you might want to check out the following guides and resources.

[

Build a prompt in the Playground

Use the Playground to develop and iterate on prompts.

](/chat/edit)[

Text generation

Learn how to prompt a model to generate text.

](/docs/guides/text)[

Engineer better prompts

Learn about OpenAI's prompt engineering tools and techniques.

](/docs/guides/prompt-engineering)

Was this page useful?