############################################################
# ellmer_basic.R
# ---------------------------------------------------------
# Purpose: Complete introduction to ellmer's six core
#          functional areas for building LLM-powered R workflows
# 
# The Six Core Areas:
#   1. Creating a Chat Object: Connecting to an LLM Provider
#   2. Conversing With the Chat Object (sync & streaming)
#   3. Asynchronous Operations (non-blocking)
#   4. Structured Data Extraction (text to R objects)
#   5. Tool/Function Calling (AI agents)
#   6. Utility and Content Helpers (images, diagnostics)
#   7. Others


############################################################
# SETUP: Install and load ellmer
############################################################

# Run this line ONCE to install ellmer
# install.packages("ellmer")

# Load the library
library(ellmer)

############################################################
# STEP 1: API Key Configuration
############################################################
# ellmer supports multiple providers (OpenAI, Anthropic, Gemini, Ollama).
# Each provider requires an API key (except Ollama for local models).
#
# WHY THIS MATTERS:
#   - API keys authenticate your requests
#   - They're tied to your billing account
#   - Never hardcode them in scripts!
#
# BEST PRACTICE: Use .Renviron file
#   1. Run: usethis::edit_r_environ()
#   2. Add: OPENAI_API_KEY=your_key_here
#   3. Save and restart R (Session > Restart R)
#   4. The key will be available via Sys.getenv("OPENAI_API_KEY")
#
# GET YOUR API KEY:
#   - OpenAI: https://platform.openai.com/api-keys
#   - Anthropic: https://console.anthropic.com/
#   - Google: https://aistudio.google.com/

# Verify API key is configured
if (identical(Sys.getenv("OPENAI_API_KEY"), "")) {
  message(
    "\n⚠️  No OPENAI_API_KEY found in environment variables.\n\n",
    "   Quick Setup:\n",
    "   1. Get an API key from: https://platform.openai.com/api-keys\n",
    "   2. Run: usethis::edit_r_environ()\n",
    "   3. Add this line: OPENAI_API_KEY=your_key_here\n",
    "   4. Save, then restart R (Session > Restart R)\n",
    "   5. Re-run this script\n"
  )
  # Uncomment the next line to stop execution if key is missing:
  # stop("Missing OPENAI_API_KEY. Please configure before continuing.")
} else {
  message("✅ OPENAI_API_KEY detected and ready to use!")
}

############################################################
# STEP 2: Create Your First Chat Object
############################################################
# A "chat object" is an R6 object that:
#   - Represents a conversation with an LLM
#   - Maintains conversation history (context)
#   - Provides methods like $chat(), $stream(), etc.
#
# Think of it like opening a chat session that remembers
# everything you've discussed.

cat("\n===== Creating a chat object =====\n")


# Create chat object with a system prompt

chat <- chat_openai(
  system_prompt = "You are a friendly R programming tutor. 
                   Explain concepts simply and use short, practical examples.",
  model = "gpt-4o-mini"  # Fast and cost-effective model
)

# MODEL OPTIONS:
#   - "gpt-4o-mini"  : Fast, cheap, great for most tasks (RECOMMENDED)
#   - "gpt-4o"       : More capable, better reasoning
#   - "gpt-4-turbo"  : Balance of speed and capability
#   - "o1"           : Most capable, for complex problems


response_1 <- chat$chat(
  "In simple terms, what is a data frame in R? 
   Keep it under 2 sentences and assume I am a beginner."
)

print(response_1)



############################################################
# STEP 4: Asking for R Code
############################################################
# One of the most powerful uses: generating R code on demand.

response_2 <- chat$chat("
Write a small R function called safe_mean() that:
  1. Takes a numeric vector x as input
  2. Removes NA values automatically
  3. Returns the mean
  4. Includes a brief comment explaining what it does

Keep it simple and beginner-friendly.
")

# TIP: Continue the conversation to refine the code
#chat$chat("Add input validation to check if x is numeric")
# chat$chat("Now add roxygen2 documentation to this function")

############################################################
# STEP 5: Using echo = "none" for Silent Capture
############################################################
# By default, ellmer streams responses to the console.
# Sometimes you want to capture output WITHOUT displaying it.
#
# USE CASES FOR SILENT MODE:
#   - Building automated workflows
#   - Using in functions
#   - Batch processing multiple queries
#   - Production scripts
#   - When you want to control when/how output is displayed


# Create a NEW chat object with echo = "none"
chat_quiet <- chat_openai(
  system_prompt = "You are a concise assistant. Answer in one sentence only.",
  model = "gpt-4o-mini",
  echo = "none"   # KEY: Prevents streaming to console
)

# This will NOT print to console during execution
quiet_answer <- chat_quiet$chat(
  "Explain what a factor is in R in one simple sentence."
)

# But we can print it ourselves when we're ready
cat("--- Answer captured silently, now displaying: ---\n")
print(quiet_answer)

# ECHO MODE OPTIONS:
#   echo = "all"   (default) - Stream everything
#   echo = "none"  - Completely silent, return only
#   echo = "text"  - Show final response but not streaming

############################################################
# STEP 6: Providing Data Context to LLMs
############################################################

# IMPORTANT CONCEPT:
# LLMs don't automatically "see" your R objects or datasets.
# You must explicitly provide context by including data information
# in your prompt.
#
# STRATEGY: Use summary(), str(), or head() output

# Capture dataset summary as text
summary_text <- capture.output(summary(iris))
summary_text <- paste(summary_text, collapse = "\n")

# Build a prompt that includes the data context
question_with_context <- paste0(
  "Here is the summary() output of a dataset called 'iris':\n\n",
  summary_text,
  "\n\n",
  "Based on this summary, please explain:\n",
  "1. How many numeric columns are there?\n",
  "2. What does the Species column contain?\n",
  "3. What's the range of Sepal.Length?\n",
  "\n",
  "Keep your answer concise and beginner-friendly."
)

# Send the question WITH context
response_4 <- chat$chat(question_with_context)

# WHY THIS WORKS:
#   - The LLM can now "see" your data structure
#   - Can make specific observations about YOUR data
#   - Avoids hallucinating or making up data details
#   - Provides accurate, relevant suggestions

# ALTERNATIVE APPROACH: Create a helper function
# This makes it reusable for any dataset:

create_data_context <- function(df, name = "dataset") {
  paste0(
    "Dataset: ", name, "\n",
    "Dimensions: ", nrow(df), " rows × ", ncol(df), " columns\n\n",
    "Structure:\n",
    paste(capture.output(str(df)), collapse = "\n"), "\n\n",
    "First 6 rows:\n",
    paste(capture.output(print(head(df))), collapse = "\n")
  )
}

# Use it with any dataset:
mtcars_context <- create_data_context(mtcars, "mtcars")


chat$chat(paste0(
  mtcars_context,
  "\n\nBased on this data, suggest an interesting ggplot2 visualization."
))

############################################################
# STEP 7: Interactive Console Mode (BONUS)
############################################################
# ellmer includes an interactive chat mode that runs in your
# R console. It's like having a conversation in the terminal.


# Uncomment to launch interactive mode:
live_console(chat)

############################################################
# STEP 8: Practical Patterns and Tips
############################################################


# PATTERN 1: Iterative Code Development
# ----------------------------------------
# Start simple, then refine through conversation

# chat$chat("Create a function to calculate the median of a vector")
# chat$chat("Add parameter validation to check for numeric input")
# chat$chat("Handle empty vectors gracefully")
# chat$chat("Add roxygen2 documentation")
# chat$chat("Now write testthat unit tests for this function")

# PATTERN 2: Code Review
# ----------------------------------------
# Get feedback on existing code

my_code <- '
calculate_total <- function(x) {
  result <- 0
  for (i in 1:length(x)) {
    result <- result + x[i]
  }
  return(result)
}
'

# Uncomment to get review:
chat$chat(paste0
          (   "Review this R code and suggest improvements:\n\n",
   my_code,
  "\n\nFocus on efficiency, readability, and R best practices."
))

# PATTERN 3: Learning Through Questions

# Use follow-up questions to deepen understanding

# chat$chat("What is the apply family of functions in R?")
# chat$chat("Can you show me an example using lapply?")
# chat$chat("When should I use sapply vs lapply?")
# chat$chat("Now show me vapply with proper type specification")

############################################################
# TIPS FOR EFFECTIVE PROMPTS

# DO:
#   - Be specific about what you want
#   - Specify output format ("as a data frame", "with comments")
#   - Provide constraints ("in 2 sentences", "using tidyverse")
#   - Give context when needed
#   - Ask for examples

# DON'T:
#   - Be vague ("help me with data")
#   - Assume the AI knows your environment
#   - Ask for overly complex tasks in one prompt
#   - Forget to specify your skill level

# GOOD PROMPT EXAMPLES:

good_prompt_1 <- "
Create a function that takes a data frame and returns a 
summary of missing values for each column. 
Include: column name, count of NAs, percentage of NAs.
Use tidyverse syntax and add brief comments.
"

good_prompt_2 <- "
I'm a beginner. Explain what %>% (the pipe operator) does in R.
Use a simple example with 2-3 steps.
"

good_prompt_3 <- "
Review this code for potential bugs and suggest improvements.
Focus on edge cases and error handling.
[paste your code here]
"

############################################################
# MANAGING CONVERSATION HISTORY


# View current conversation turns
current_history <- chat$get_turns()
print(current_history)

# Clear history when switching to a new topic
# This is important because:
#   - Saves on API costs (fewer tokens sent)
#   - Prevents confusion from unrelated context
#   - Starts fresh for new tasks

chat$set_turns(list())

# Verify it's cleared
cat("Conversation now has", length(chat$get_turns()), "turns\n")

############################################################
# ERROR HANDLING FOR PRODUCTION USE

# When using ellmer in production code, wrap calls in tryCatch
safe_chat <- function(chat_obj, prompt, max_retries = 3) {
  for (attempt in 1:max_retries) {
    result <- tryCatch({
      chat_obj$chat(prompt)
    }, error = function(e) {
      if (grepl("rate limit", e$message, ignore.case = TRUE)) {
        # Handle rate limiting with exponential backoff
        wait_time <- 2^attempt
        message("Rate limited. Waiting ", wait_time, " seconds...")
        Sys.sleep(wait_time)
        NULL
      } else {
        # Log error and return NULL
        message("Error: ", e$message)
        NULL
      }
    })
    
    if (!is.null(result)) return(result)
  }
  
  stop("Failed after ", max_retries, " attempts")
}

# Usage:
safe_response <- safe_chat(chat, "What is dplyr?")

############################################################
# COMPARING DIFFERENT PROVIDERS
############################################################

# You can create chat objects for different providers:

# OpenAI (GPT models)
# chat_gpt <- chat_openai(
#   system_prompt = "You are a helpful R assistant.",
#   model = "gpt-4o-mini"
# )

# Anthropic (Claude models) - requires ANTHROPIC_API_KEY
# chat_claude <- chat_claude(
#   system_prompt = "You are a helpful R assistant.",
#   model = "claude-3-5-sonnet-20241022"
# )

# Google (Gemini models) - requires GOOGLE_API_KEY
# chat_gemini <- chat_gemini(
#   system_prompt = "You are a helpful R assistant.",
#   model = "gemini-1.5-flash"
# )

# Local models (Ollama) - no API key needed, but requires Ollama running
# chat_local <- chat_ollama(
#   system_prompt = "You are a helpful R assistant.",
#   model = "llama3"
# )

# All chat objects work the same way regardless of provider!

############################################################
# COMPLETE WORKING EXAMPLE
############################################################

# This example shows a typical workflow combining everything:

workflow_demo <- function() {
  # 1. Create specialized chat object
  analyst <- chat_openai(
    system_prompt = "You are a data analyst. Provide practical,
                     code-based solutions using tidyverse when possible.",
    model = "gpt-4o-mini",
    echo = "none"  # Silent mode for clean workflow
  )
  
  # 2. Get data context
  data_info <- create_data_context(iris, "iris")
  
  # 3. Ask for analysis suggestions
  suggestions <- analyst$chat(paste0(
    data_info,
    "\n\nSuggest 3 interesting analyses for this dataset.",
    "Be specific and actionable."
  ))
  
  cat("Analysis Suggestions:\n")
  cat(suggestions, "\n\n")
  
  # 4. Request specific code
  code <- analyst$chat(
    "Write ggplot2 code to create a scatter plot of Sepal.Length 
     vs Sepal.Width, colored by Species, with a smooth trend line."
  )
  
  cat("Generated Code:\n")
  cat(code, "\n\n")
  
  # 5. Ask for interpretation help
  interpretation <- analyst$chat(
    "Based on the iris dataset, what relationship would we expect
     to see between Sepal.Length and Sepal.Width? Explain in 2 sentences."
  )
  
  cat("Interpretation:\n")
  cat(interpretation, "\n")
  
  return(list(
    suggestions = suggestions,
    code = code,
    interpretation = interpretation
  ))
}

# Uncomment to run the complete workflow:
results <- workflow_demo()

############################################################