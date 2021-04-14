
# # LinkAggregator

# ## Introduction

# Steps on how to build a simple link aggregator site in ASP.NET Core.
#
# ![](screenshot-links.jpg)
#
# Currently implemented features:
# 
# - Multiple users
# - Voting
#
# In this early version of the tutorial, the following aren't implemented:
#
# - Authorization
# - Comments
#
# Currently only tested on Windows.

# This tutorial assumes that you've worked through some simple ASP.NET Core examples already. 
# So, it doesn't explain every little detail along the way.
# In this sense, it's more of a step-by-step cookbook recipe-style guide.

# ## About this document

# This tutorial was generated from a source file written in PowerShell.

# That source file, when executed, will go through all the steps shown in this tutorial.
# Thus the tutorial can always be validated to make sure that the steps are working properly by running the source file.
# Feel free to run the source file before going through the tutorial to verify that the tutorial works on your system.

# IGNORE-START
# Set-PSDebug -Trace 0
# Set-PSDebug -Trace 1

$ErrorActionPreference = 'Stop'
# ----------------------------------------------------------------------
# function Edit ($File, $Replacing, $With)
# {
#     (Get-Content $File -Raw).Replace($Replacing, $With) | Set-Content -NoNewline $File
# }
# ----------------------------------------------------------------------
# IGNORE-END

# # Project directory

# Go to the directory where our project will be created.
        
    cd C:\Users\dharm\Dropbox\Documents\VisualStudio\LinkAggregatorTutorial

# IGNORE-START
if (Test-Path LinkAggregator)
{
    $date = Get-Date -Format 'yyyy-MM-dd-HH-mm'

    Move-Item LinkAggregator _LinkAggregator-$date
}
# IGNORE-END

# ----------------------------------------------------------------------
    New-Item -ItemType Directory -Name LinkAggregator

    cd LinkAggregator

    dotnet new webapp --auth Individual --use-local-db

    dotnet new gitignore

    git init

$ErrorActionPreference = 'Continue' # IGNORE-LINE-FOR-MARKDOWN
    git add . 
$ErrorActionPreference = 'Stop' # IGNORE-LINE-FOR-MARKDOWN

    git commit --message 'Initial checkin'
# ----------------------------------------------------------------------

# # `Link` model class for storing links

@"
diff --git a/Models/Link.cs b/Models/Link.cs
new file mode 100644
index 0000000..29de407
--- /dev/null
+++ b/Models/Link.cs
@@ -0,0 +1,12 @@
+using System;
+
+namespace LinkAggregator.Models
+{
+    public class Link
+    {
+        public int Id { get; set; }
+        public string UserId { get; set; }
+        public string Url { get; set; }
+        public DateTime DateTime { get; set; }
+    }
+}
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Add Link.cs'
# ----------------------------------------------------------------------

# # Generate pages for `Link`

    dotnet add package Microsoft.VisualStudio.Web.CodeGeneration.Design

$ErrorActionPreference = 'Continue' # IGNORE-LINE-FOR-MARKDOWN
    dotnet tool install --global dotnet-aspnet-codegenerator
$ErrorActionPreference = 'Stop' # IGNORE-LINE-FOR-MARKDOWN

    dotnet aspnet-codegenerator razorpage `
        -m Link `
        --useDefaultLayout `
        --dataContext        ApplicationDbContext `
        --relativeFolderPath Pages\Links `
        --referenceScriptLibraries
    
    dotnet ef database drop -f

    dotnet ef migrations add Initial

    dotnet ef database update

    git add . ; git commit --message 'Add Link pages via scaffolding'
# ----------------------------------------------------------------------

# Change encoding of `_Layout.cshtml`:

    (Get-Content .\Pages\Shared\_Layout.cshtml) | Set-Content .\Pages\Shared\_Layout.cshtml

    git add . ; git commit --message 'encoding'
# ----------------------------------------------------------------------

# Update LinkAggregator anchor

@"
diff --git a/Pages/Shared/_Layout.cshtml b/Pages/Shared/_Layout.cshtml
index 0465ef6..bdbe9ce 100644
--- a/Pages/Shared/_Layout.cshtml
+++ b/Pages/Shared/_Layout.cshtml
@@ -11,7 +11,7 @@
     <header>
         <nav class="navbar navbar-expand-sm navbar-toggleable-sm navbar-light bg-white border-bottom box-shadow mb-3">
             <div class="container">
-                <a class="navbar-brand" asp-area="" asp-page="/Index">LinkAggregator</a>
+                <a class="navbar-brand" asp-area="" asp-page="/Links/Index">LinkAggregator</a>
                 <button class="navbar-toggler" type="button" data-toggle="collapse" data-target=".navbar-collapse" aria-controls="navbarSupportedContent"
                         aria-expanded="false" aria-label="Toggle navigation">
                     <span class="navbar-toggler-icon"></span>
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Update LinkAggregator anchor'
# ----------------------------------------------------------------------

# IGNORE-START
# @"
# using LinkAggregator.Models;
# using Microsoft.EntityFrameworkCore;
# using Microsoft.Extensions.DependencyInjection;
# using System;
# using System.Linq;
# using System.Threading.Tasks;
# 
# namespace LinkAggregator.Data
# {
#     public static class SeedData
#     {
#         public static async Task Initialize(IServiceProvider serviceProvider, string testUserPw)
#         {
#             using (var context = new ApplicationDbContext(
#                 serviceProvider.GetRequiredService<DbContextOptions<ApplicationDbContext>>()))
#             {              
#                 SeedDB(context, "0");
#             }
#         }        
# 
#         public static void SeedDB(ApplicationDbContext context, string adminID)
#         {
#             if (context.Link.Any())
#             {
#                 return;   // DB has been seeded
#             }
# 
#             context.Link.AddRange(
#                 new Link() 
#                 { 
#                     Url = "https://asp.net"
#                 },
#                 new Link()
#                 {
#                     Url = "https://www.gnu.org"
#                 }
#              );
#             context.SaveChanges();
#         }
# 
#     }
# }
# "@ | Set-Content .\Data\SeedData.cs


# ----------------------------------------------------------------------

# @"
# using LinkAggregator.Data;
# using Microsoft.AspNetCore.Hosting;
# using Microsoft.EntityFrameworkCore;
# using Microsoft.Extensions.DependencyInjection;
# using Microsoft.Extensions.Hosting;
# using Microsoft.Extensions.Logging;
# using System;
# 
# namespace LinkAggregator
# {
#     public class Program
#     {
#         public static void Main(string[] args)
#         {
#             var host = CreateHostBuilder(args).Build();
# 
#             using (var scope = host.Services.CreateScope())
#             {
#                 var services = scope.ServiceProvider;
# 
#                 try
#                 {
#                     var context = services.GetRequiredService<ApplicationDbContext>();
#                     context.Database.Migrate();
#                     SeedData.Initialize(services, "not used");
#                 }
#                 catch (Exception ex)
#                 {
#                     var logger = services.GetRequiredService<ILogger<Program>>();
#                     logger.LogError(ex, "An error occurred seeding the DB.");
#                 }
#             }
# 
#             host.Run();
#         }
# 
#         public static IHostBuilder CreateHostBuilder(string[] args) =>
#             Host.CreateDefaultBuilder(args)
#                 .ConfigureWebHostDefaults(webBuilder =>
#                 {
#                     webBuilder.UseStartup<Startup>();
#                 });
#     }
# }
# "@ | Set-Content .\Program.cs
# 
# git add . ; git commit --message 'SeedData'
# ----------------------------------------------------------------------
# IGNORE-END

# # Adding new links

# A user that isn't logged in can add an entry.
#
# Let's make it so that only logged in users can add links.

@"
diff --git a/Pages/Links/Create.cshtml.cs b/Pages/Links/Create.cshtml.cs
index fed813d..f1ee9d0 100644
--- a/Pages/Links/Create.cshtml.cs
+++ b/Pages/Links/Create.cshtml.cs
@@ -24,6 +24,9 @@ namespace LinkAggregator.Pages.Links
 
         public IActionResult OnGet()
         {
+            if (User.Identity.Name == null)
+                return RedirectToPage("./Index");
+
             return Page();
         }
 

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'User must be logged in to add a link'
# ----------------------------------------------------------------------

# # Identity pages

# Scaffold out the identity pages

    dotnet add package Microsoft.VisualStudio.Web.CodeGeneration.Design
    dotnet add package Microsoft.EntityFrameworkCore.Design
    dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
    dotnet add package Microsoft.AspNetCore.Identity.UI
    dotnet add package Microsoft.EntityFrameworkCore.SqlServer
    dotnet add package Microsoft.EntityFrameworkCore.Tools

    dotnet aspnet-codegenerator identity `
        --dbContext LinkAggregator.Data.ApplicationDbContext

    git add . ; git commit --message 'Identity pages'

# ----------------------------------------------------------------------

# # Create form - remove `UserId`

# The 'Create' form has a field for `UserId`. We shouldn't have to enter this. Let's remove this field.

# ----------------------------------------------------------------------
# Add `UserManager` to `CreateModel`

@"
diff --git a/Pages/Links/Create.cshtml.cs b/Pages/Links/Create.cshtml.cs
index 2056883..9dd7fe7 100644
--- a/Pages/Links/Create.cshtml.cs
+++ b/Pages/Links/Create.cshtml.cs
@@ -7,16 +7,19 @@ using Microsoft.AspNetCore.Mvc.RazorPages;
 using Microsoft.AspNetCore.Mvc.Rendering;
 using LinkAggregator.Data;
 using LinkAggregator.Models;
+using Microsoft.AspNetCore.Identity;
 
 namespace LinkAggregator.Pages.Links
 {
     public class CreateModel : PageModel
     {
-        private readonly LinkAggregator.Data.ApplicationDbContext _context;
+        private readonly ApplicationDbContext _context;
+        private UserManager<IdentityUser> UserManager { get; }
 
-        public CreateModel(LinkAggregator.Data.ApplicationDbContext context)
+        public CreateModel(ApplicationDbContext context, UserManager<IdentityUser> userManager)
         {
             _context = context;
+            UserManager = userManager;
         }
 
         public IActionResult OnGet()
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links\Create.cshtml.cs - UserManager'
# ----------------------------------------------------------------------
# Populate `Link.UserId` automatically with id of current user.

@"
diff --git a/Pages/Links/Create.cshtml.cs b/Pages/Links/Create.cshtml.cs
index 9dd7fe7..fed813d 100644
--- a/Pages/Links/Create.cshtml.cs
+++ b/Pages/Links/Create.cshtml.cs
@@ -38,6 +38,8 @@ namespace LinkAggregator.Pages.Links
                 return Page();
             }
 
+            Link.UserId = UserManager.GetUserId(User);
+
             _context.Link.Add(Link);
             await _context.SaveChangesAsync();
 
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links\Create.cshtml.cs - populate UserId field'
# ----------------------------------------------------------------------

# Remove UserId field from create form frontend.

@"
diff --git a/Pages/Links/Create.cshtml b/Pages/Links/Create.cshtml
index 7ac2d77..a12e5c6 100644
--- a/Pages/Links/Create.cshtml
+++ b/Pages/Links/Create.cshtml
@@ -13,11 +13,7 @@
     <div class="col-md-4">
         <form method="post">
             <div asp-validation-summary="ModelOnly" class="text-danger"></div>
-            <div class="form-group">
-                <label asp-for="Link.UserId" class="control-label"></label>
-                <input asp-for="Link.UserId" class="form-control" />
-                <span asp-validation-for="Link.UserId" class="text-danger"></span>
-            </div>
+            
             <div class="form-group">
                 <label asp-for="Link.Url" class="control-label"></label>
                 <input asp-for="Link.Url" class="form-control" />
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links\Create.cshtml - remove UserId field'
# ----------------------------------------------------------------------

# # Create form: remove `DateTime`

# The create form has a field for `DateTime`.
#
# It's a field for storing the time that the link was created.
# 
# The user shouldn't have to fill this in.

# ----------------------------------------------------------------------
@"
diff --git a/Pages/Links/Create.cshtml.cs b/Pages/Links/Create.cshtml.cs
index fed813d..a8b0f67 100644
--- a/Pages/Links/Create.cshtml.cs
+++ b/Pages/Links/Create.cshtml.cs
@@ -40,6 +40,8 @@ namespace LinkAggregator.Pages.Links
 
             Link.UserId = UserManager.GetUserId(User);
 
+            Link.DateTime = DateTime.Now;
+
             _context.Link.Add(Link);
             await _context.SaveChangesAsync();
 
"@ | git apply --whitespace=nowarn
# ----------------------------------------------------------------------
@"
diff --git a/Pages/Links/Create.cshtml b/Pages/Links/Create.cshtml
index a12e5c6..0f7a2d7 100644
--- a/Pages/Links/Create.cshtml
+++ b/Pages/Links/Create.cshtml
@@ -19,11 +19,7 @@
                 <input asp-for="Link.Url" class="form-control" />
                 <span asp-validation-for="Link.Url" class="text-danger"></span>
             </div>
-            <div class="form-group">
-                <label asp-for="Link.DateTime" class="control-label"></label>
-                <input asp-for="Link.DateTime" class="form-control" />
-                <span asp-validation-for="Link.DateTime" class="text-danger"></span>
-            </div>
+            
             <div class="form-group">
                 <input type="submit" value="Create" class="btn btn-primary" />
             </div>
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Create form - remove field for DateTime'
# ----------------------------------------------------------------------

# # Link model: add field for `Title`

# Currently, the user can only supply a url when adding a link.
# Most link aggregation sites allow the user to provide a title.
# Let's add a field for the link title.

@"
diff --git a/Models/Link.cs b/Models/Link.cs
index 29de407..65cc4c4 100644
--- a/Models/Link.cs
+++ b/Models/Link.cs
@@ -7,6 +7,7 @@ namespace LinkAggregator.Models
         public int Id { get; set; }
         public string UserId { get; set; }
         public string Url { get; set; }
+        public string Title { get; set; }
         public DateTime DateTime { get; set; }
     }
 }
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Models\Link.cs - Title field'
# ----------------------------------------------------------------------
    dotnet ef migrations add AddLinkTitle
    dotnet ef database update

    git add . ; git commit --message 'dotnet ef migrations add AddLinkTitle'
# ----------------------------------------------------------------------
@"
diff --git a/Pages/Links/Create.cshtml b/Pages/Links/Create.cshtml
index 0f7a2d7..f81ef90 100644
--- a/Pages/Links/Create.cshtml
+++ b/Pages/Links/Create.cshtml
@@ -13,13 +13,19 @@
     <div class="col-md-4">
         <form method="post">
             <div asp-validation-summary="ModelOnly" class="text-danger"></div>
-            
+
+            <div class="form-group">
+                <label asp-for="Link.Title" class="control-label"></label>
+                <input asp-for="Link.Title" class="form-control"></input>
+                <span asp-validation-for="Link.Title" class="text-danger"></span>
+            </div>
+
             <div class="form-group">
                 <label asp-for="Link.Url" class="control-label"></label>
                 <input asp-for="Link.Url" class="form-control" />
                 <span asp-validation-for="Link.Url" class="text-danger"></span>
             </div>
-            
+
             <div class="form-group">
                 <input type="submit" value="Create" class="btn btn-primary" />
             </div>
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links\Create.cshtml - add field for Title'
# ----------------------------------------------------------------------
@"
diff --git a/Pages/Links/Index.cshtml b/Pages/Links/Index.cshtml
index 4e46774..dfffe05 100644
--- a/Pages/Links/Index.cshtml
+++ b/Pages/Links/Index.cshtml
@@ -16,6 +16,9 @@
             <th>
                 @Html.DisplayNameFor(model => model.Link[0].UserId)
             </th>
+            <th>
+                @Html.DisplayNameFor(model => model.Link[0].Title)
+            </th>
             <th>
                 @Html.DisplayNameFor(model => model.Link[0].Url)
             </th>
@@ -31,6 +34,11 @@
             <td>
                 @Html.DisplayFor(modelItem => item.UserId)
             </td>
+
+            <td>
+                @Html.DisplayFor(modelItem => item.Title)
+            </td>
+
             <td>
                 @Html.DisplayFor(modelItem => item.Url)
             </td>
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links\Index.cshtml - add field for Title'
# ----------------------------------------------------------------------

# Add title to details page

@"
diff --git a/Pages/Links/Details.cshtml b/Pages/Links/Details.cshtml
index e4c1c67..37ade6b 100644
--- a/Pages/Links/Details.cshtml
+++ b/Pages/Links/Details.cshtml
@@ -17,6 +17,12 @@
         <dd class="col-sm-10">
             @Html.DisplayFor(model => model.Link.UserId)
         </dd>
+        <dt class="col-sm-2">
+            @Html.DisplayNameFor(model => model.Link.Title)
+        </dt>
+        <dd class="col-sm-10">
+            @Html.DisplayFor(model => model.Link.Title)
+        </dd>
         <dt class="col-sm-2">
             @Html.DisplayNameFor(model => model.Link.Url)
         </dt>

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links\Details.cshtml - add field for Title'
# ----------------------------------------------------------------------

# # Link index: Only show title

# Link aggregation sites don't usually display the full URL in the link list.
#
# Let's remove the URL from the link list page.

@"
diff --git a/Pages/Links/Index.cshtml b/Pages/Links/Index.cshtml
index dfffe05..ea221d2 100644
--- a/Pages/Links/Index.cshtml
+++ b/Pages/Links/Index.cshtml
@@ -19,9 +19,6 @@
             <th>
                 @Html.DisplayNameFor(model => model.Link[0].Title)
             </th>
-            <th>
-                @Html.DisplayNameFor(model => model.Link[0].Url)
-            </th>
             <th>
                 @Html.DisplayNameFor(model => model.Link[0].DateTime)
             </th>
@@ -39,9 +36,6 @@
                 @Html.DisplayFor(modelItem => item.Title)
             </td>
 
-            <td>
-                @Html.DisplayFor(modelItem => item.Url)
-            </td>
             <td>
                 @Html.DisplayFor(modelItem => item.DateTime)
             </td>
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links\Index.cshtml - remove field for Url'
# ----------------------------------------------------------------------

# # URL validation

# Currently, the url field on the create form allows any value to be submitted.
# Let's make it only accept properly formatted URLs.

@"
diff --git a/Models/Link.cs b/Models/Link.cs
index 65cc4c4..f2aebcc 100644
--- a/Models/Link.cs
+++ b/Models/Link.cs
@@ -1,4 +1,5 @@
 using System;
+using System.ComponentModel.DataAnnotations;
 
 namespace LinkAggregator.Models
 {
@@ -6,7 +7,10 @@ namespace LinkAggregator.Models
     {
         public int Id { get; set; }
         public string UserId { get; set; }
+
+        [DataType(DataType.Url)]
         public string Url { get; set; }
+
         public string Title { get; set; }
         public DateTime DateTime { get; set; }
     }
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Models\Link.cs - DataType.Url'
# ----------------------------------------------------------------------

# # Link index: DateTime formatting

# The DateTime field on the link list shows the time as well as the date.
# Let's have it only display the date.

@"
diff --git a/Models/Link.cs b/Models/Link.cs
index f2aebcc..4582dea 100644
--- a/Models/Link.cs
+++ b/Models/Link.cs
@@ -12,6 +12,9 @@ namespace LinkAggregator.Models
         public string Url { get; set; }
 
         public string Title { get; set; }
+
+        [Display(Name = "Date")]
+        [DataType(DataType.Date)]
         public DateTime DateTime { get; set; }
     }
 }
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Models\Link.cs - DataType.Date for DateTime'
# ----------------------------------------------------------------------

# # Adding support for usernames

# Users have usernames on most link aggregation sites.
# Currently, when a new user registers, they are only asked for an email address and this is used as their username.
# Let's have the user supply a username in addition to their email address.

@"
diff --git a/Areas/Identity/Pages/Account/Register.cshtml.cs b/Areas/Identity/Pages/Account/Register.cshtml.cs
index 3c92469..08d916e 100644
--- a/Areas/Identity/Pages/Account/Register.cshtml.cs
+++ b/Areas/Identity/Pages/Account/Register.cshtml.cs
@@ -45,6 +45,11 @@ namespace LinkAggregator.Areas.Identity.Pages.Account
 
         public class InputModel
         {
+            [Required]
+            [DataType(DataType.Text)]
+            [Display(Name = "User Name")]
+            public string UserName { get; set; }
+
             [Required]
             [EmailAddress]
             [Display(Name = "Email")]
@@ -74,7 +79,7 @@ namespace LinkAggregator.Areas.Identity.Pages.Account
             ExternalLogins = (await _signInManager.GetExternalAuthenticationSchemesAsync()).ToList();
             if (ModelState.IsValid)
             {
-                var user = new IdentityUser { UserName = Input.Email, Email = Input.Email };
+                var user = new IdentityUser { UserName = Input.UserName, Email = Input.Email };
                 var result = await _userManager.CreateAsync(user, Input.Password);
                 if (result.Succeeded)
                 {
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Register.cshtml.cs - Username'
# ----------------------------------------------------------------------
@"
diff --git a/Areas/Identity/Pages/Account/Register.cshtml b/Areas/Identity/Pages/Account/Register.cshtml
index 96e6a9a..efa8667 100644
--- a/Areas/Identity/Pages/Account/Register.cshtml
+++ b/Areas/Identity/Pages/Account/Register.cshtml
@@ -12,6 +12,13 @@
             <h4>Create a new account.</h4>
             <hr />
             <div asp-validation-summary="All" class="text-danger"></div>
+
+            <div class="form-group">
+                <label asp-for="Input.UserName"></label>
+                <input asp-for="Input.UserName" class="form-control" />
+                <span asp-validation-for="Input.UserName" class="text-danger"></span>
+            </div>
+
             <div class="form-group">
                 <label asp-for="Input.Email"></label>
                 <input asp-for="Input.Email" class="form-control" />
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Register.cshtml - Username'
# ----------------------------------------------------------------------
@"
diff --git a/Areas/Identity/Pages/Account/Login.cshtml.cs b/Areas/Identity/Pages/Account/Login.cshtml.cs
index 3d0719d..54c64a8 100644
--- a/Areas/Identity/Pages/Account/Login.cshtml.cs
+++ b/Areas/Identity/Pages/Account/Login.cshtml.cs
@@ -43,8 +43,9 @@ namespace LinkAggregator.Areas.Identity.Pages.Account
         public class InputModel
         {
             [Required]
-            [EmailAddress]
-            public string Email { get; set; }
+            [DataType(DataType.Text)]
+            [Display(Name = "User Name")]
+            public string UserName { get; set; }
 
             [Required]
             [DataType(DataType.Password)]
@@ -81,7 +82,7 @@ namespace LinkAggregator.Areas.Identity.Pages.Account
             {
                 // This doesn't count login failures towards account lockout
                 // To enable password failures to trigger account lockout, set lockoutOnFailure: true
-                var result = await _signInManager.PasswordSignInAsync(Input.Email, Input.Password, Input.RememberMe, lockoutOnFailure: false);
+                var result = await _signInManager.PasswordSignInAsync(Input.UserName, Input.Password, Input.RememberMe, lockoutOnFailure: false);
                 if (result.Succeeded)
                 {
                     _logger.LogInformation("User logged in.");
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Login.cshtml.cs - UserName'
# ----------------------------------------------------------------------
@"
diff --git a/Areas/Identity/Pages/Account/Login.cshtml b/Areas/Identity/Pages/Account/Login.cshtml
index 72a567f..6d374b9 100644
--- a/Areas/Identity/Pages/Account/Login.cshtml
+++ b/Areas/Identity/Pages/Account/Login.cshtml
@@ -14,9 +14,9 @@
                 <hr />
                 <div asp-validation-summary="All" class="text-danger"></div>
                 <div class="form-group">
-                    <label asp-for="Input.Email"></label>
-                    <input asp-for="Input.Email" class="form-control" />
-                    <span asp-validation-for="Input.Email" class="text-danger"></span>
+                    <label asp-for="Input.UserName"></label>
+                    <input asp-for="Input.UserName" class="form-control" />
+                    <span asp-validation-for="Input.UserName" class="text-danger"></span>
                 </div>
                 <div class="form-group">
                     <label asp-for="Input.Password"></label>
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Login.cshtml - UserName'
# ----------------------------------------------------------------------

# The links list currently shows a UserId for each link.
# Let's display the username instead.

@"
diff --git a/Pages/Links/Index.cshtml.cs b/Pages/Links/Index.cshtml.cs
index c2ac2a5..aa27ac4 100644
--- a/Pages/Links/Index.cshtml.cs
+++ b/Pages/Links/Index.cshtml.cs
@@ -7,20 +7,25 @@ using Microsoft.AspNetCore.Mvc.RazorPages;
 using Microsoft.EntityFrameworkCore;
 using LinkAggregator.Data;
 using LinkAggregator.Models;
+using Microsoft.AspNetCore.Identity;
 
 namespace LinkAggregator.Pages.Links
 {
     public class IndexModel : PageModel
     {
-        private readonly LinkAggregator.Data.ApplicationDbContext _context;
+        private readonly ApplicationDbContext _context;
+        private UserManager<IdentityUser> UserManager { get; }
 
-        public IndexModel(LinkAggregator.Data.ApplicationDbContext context)
+        public IndexModel(ApplicationDbContext context, UserManager<IdentityUser> userManager)
         {
             _context = context;
+            UserManager = userManager;
         }
 
         public IList<Link> Link { get;set; }
 
+        public IdentityUser LinkUser(Link link) => UserManager.FindByIdAsync(link.UserId).Result;
+
         public async Task OnGetAsync()
         {
             Link = await _context.Link.ToListAsync();
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Login.cshtml.cs - LinkUser method'
# ----------------------------------------------------------------------
@"
diff --git a/Pages/Links/Index.cshtml b/Pages/Links/Index.cshtml
index ea221d2..23d0564 100644
--- a/Pages/Links/Index.cshtml
+++ b/Pages/Links/Index.cshtml
@@ -14,7 +14,7 @@
     <thead>
         <tr>
             <th>
-                @Html.DisplayNameFor(model => model.Link[0].UserId)
+                User Name
             </th>
             <th>
                 @Html.DisplayNameFor(model => model.Link[0].Title)
@@ -29,7 +29,7 @@
 @foreach (var item in Model.Link) {
         <tr>
             <td>
-                @Html.DisplayFor(modelItem => item.UserId)
+                @Html.DisplayFor(modelItem => Model.LinkUser(item).UserName)
             </td>
 
             <td>
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Login.cshtml - UserName'
# ----------------------------------------------------------------------

# # Clickable title

# Let's make the title a clickable link on the link list

@"
diff --git a/Pages/Links/Index.cshtml b/Pages/Links/Index.cshtml
index 23d0564..d110e0c 100644
--- a/Pages/Links/Index.cshtml
+++ b/Pages/Links/Index.cshtml
@@ -33,7 +33,9 @@
             </td>
 
             <td>
-                @Html.DisplayFor(modelItem => item.Title)
+                <a href="@item.Url">
+                    @Html.DisplayFor(modelItem => item.Title)
+                </a>
             </td>
 
             <td>

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links.cshtml - make Title clickable link'
# ----------------------------------------------------------------------

# IGNORE-START
# seed data
# IGNORE-END

# # Voting

# Users should be able to vote on links.
# Let's add this now.

# ----------------------------------------------------------------------

@"
diff --git a/Models/Vote.cs b/Models/Vote.cs
new file mode 100644
index 0000000..13d3036
--- /dev/null
+++ b/Models/Vote.cs
@@ -0,0 +1,18 @@
+using System;
+using System.Collections.Generic;
+using System.Linq;
+using System.Threading.Tasks;
+
+namespace LinkAggregator.Models
+{
+    public class Vote
+    {
+        public int Id { get; set; }
+        public string UserId { get; set; }
+        public int Score { get; set; }
+        public DateTime DateTime { get; set; }
+
+        public int LinkId { get; set; }
+        public Link Link { get; set; }
+    }
+}

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Models\Vote.cs'
# ----------------------------------------------------------------------
@"
diff --git a/Models/Link.cs b/Models/Link.cs
index 4582dea..5e1e9e6 100644
--- a/Models/Link.cs
+++ b/Models/Link.cs
@@ -1,4 +1,5 @@
 using System;
+using System.Collections.Generic;
 using System.ComponentModel.DataAnnotations;
 
 namespace LinkAggregator.Models
@@ -16,5 +17,7 @@ namespace LinkAggregator.Models
         [Display(Name = "Date")]
         [DataType(DataType.Date)]
         public DateTime DateTime { get; set; }
+
+        public List<Vote> Votes { get; set; }
     }
 }

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Link.cs - Votes navigation property'
# ----------------------------------------------------------------------
@"
diff --git a/Data/ApplicationDbContext.cs b/Data/ApplicationDbContext.cs
index f647429..cae0049 100644
--- a/Data/ApplicationDbContext.cs
+++ b/Data/ApplicationDbContext.cs
@@ -14,5 +14,7 @@ namespace LinkAggregator.Data
         {
         }
         public DbSet<LinkAggregator.Models.Link> Link { get; set; }
+
+        public DbSet<Vote> Vote { get; set; }
     }
 }
"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'ApplicationDbContext.cs - Vote'
# ----------------------------------------------------------------------
@"
diff --git a/Data/ApplicationDbContext.cs b/Data/ApplicationDbContext.cs
index cae0049..6758500 100644
--- a/Data/ApplicationDbContext.cs
+++ b/Data/ApplicationDbContext.cs
@@ -13,7 +13,7 @@ namespace LinkAggregator.Data
             : base(options)
         {
         }
-        public DbSet<LinkAggregator.Models.Link> Link { get; set; }
+        public DbSet<Link> Link { get; set; }
 
         public DbSet<Vote> Vote { get; set; }
     }

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'ApplicationDbContext.cs - simplify reference'
# ----------------------------------------------------------------------
    dotnet ef migrations add Vote

    dotnet ef database update
# ----------------------------------------------------------------------
@"
diff --git a/Models/Link.cs b/Models/Link.cs
index 5e1e9e6..ce0cfba 100644
--- a/Models/Link.cs
+++ b/Models/Link.cs
@@ -1,6 +1,7 @@
 using System;
 using System.Collections.Generic;
 using System.ComponentModel.DataAnnotations;
+using System.Linq;
 
 namespace LinkAggregator.Models
 {
@@ -19,5 +20,7 @@ namespace LinkAggregator.Models
         public DateTime DateTime { get; set; }
 
         public List<Vote> Votes { get; set; }
+
+        public int Score() => Votes.Sum(vote => vote.Score);
     }
 }

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Link - Score method'
# ----------------------------------------------------------------------
@"
diff --git a/Pages/Links/Index.cshtml.cs b/Pages/Links/Index.cshtml.cs
index aa27ac4..c3414a9 100644
--- a/Pages/Links/Index.cshtml.cs
+++ b/Pages/Links/Index.cshtml.cs
@@ -28,7 +28,9 @@ namespace LinkAggregator.Pages.Links
 
         public async Task OnGetAsync()
         {
-            Link = await _context.Link.ToListAsync();
+            Link = await _context.Link
+                .Include(link => link.Votes)
+                .ToListAsync();
         }
     }
 }

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message '.\Pages\Links\Index.cshtml.cs - include Votes navigation property'
# ----------------------------------------------------------------------
@"
diff --git a/Pages/Links/Index.cshtml.cs b/Pages/Links/Index.cshtml.cs
index c3414a9..d864cb8 100644
--- a/Pages/Links/Index.cshtml.cs
+++ b/Pages/Links/Index.cshtml.cs
@@ -22,13 +22,13 @@ namespace LinkAggregator.Pages.Links
             UserManager = userManager;
         }
 
-        public IList<Link> Link { get;set; }
+        public IList<Link> Links { get;set; }
 
         public IdentityUser LinkUser(Link link) => UserManager.FindByIdAsync(link.UserId).Result;
 
         public async Task OnGetAsync()
         {
-            Link = await _context.Link
+            Links = await _context.Link
                 .Include(link => link.Votes)
                 .ToListAsync();
         }

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message '.\Pages\Links\Index.cshtml.cs - pluralize Link property to Links'
# ----------------------------------------------------------------------
@"
diff --git a/Pages/Links/Index.cshtml b/Pages/Links/Index.cshtml
index d110e0c..d6c354b 100644
--- a/Pages/Links/Index.cshtml
+++ b/Pages/Links/Index.cshtml
@@ -17,34 +17,34 @@
                 User Name
             </th>
             <th>
-                @Html.DisplayNameFor(model => model.Link[0].Title)
+                @Html.DisplayNameFor(model => model.Links[0].Title)
             </th>
             <th>
-                @Html.DisplayNameFor(model => model.Link[0].DateTime)
+                @Html.DisplayNameFor(model => model.Links[0].DateTime)
             </th>
             <th></th>
         </tr>
     </thead>
     <tbody>
-@foreach (var item in Model.Link) {
+@foreach (var link in Model.Links) {
         <tr>
             <td>
-                @Html.DisplayFor(modelItem => Model.LinkUser(item).UserName)
+                @Html.DisplayFor(modelItem => Model.LinkUser(link).UserName)
             </td>
 
             <td>
-                <a href="@item.Url">
-                    @Html.DisplayFor(modelItem => item.Title)
+                <a href="@link.Url">
+                    @Html.DisplayFor(modelItem => link.Title)
                 </a>
             </td>
 
             <td>
-                @Html.DisplayFor(modelItem => item.DateTime)
+                @Html.DisplayFor(modelItem => link.DateTime)
             </td>
             <td>
-                <a asp-page="./Edit" asp-route-id="@item.Id">Edit</a> |
-                <a asp-page="./Details" asp-route-id="@item.Id">Details</a> |
-                <a asp-page="./Delete" asp-route-id="@item.Id">Delete</a>
+                <a asp-page="./Edit" asp-route-id="@link.Id">Edit</a> |
+                <a asp-page="./Details" asp-route-id="@link.Id">Details</a> |
+                <a asp-page="./Delete" asp-route-id="@link.Id">Delete</a>
             </td>
         </tr>
 }

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links\Index.cshtml - Rename parameter "item" to "link"'
# ----------------------------------------------------------------------
@"
diff --git a/Models/Link.cs b/Models/Link.cs
index ce0cfba..8c2693a 100644
--- a/Models/Link.cs
+++ b/Models/Link.cs
@@ -2,6 +2,7 @@ using System;
 using System.Collections.Generic;
 using System.ComponentModel.DataAnnotations;
 using System.Linq;
+using System.Threading.Tasks;
 
 namespace LinkAggregator.Models
 {
@@ -22,5 +23,29 @@ namespace LinkAggregator.Models
         public List<Vote> Votes { get; set; }
 
         public int Score() => Votes.Sum(vote => vote.Score);
+
+        public Vote UserVote(string userId) => Votes.FirstOrDefault(vote => vote.UserId == userId);
+
+        public async Task Vote(int score, string voterUserId)
+        {
+            var vote = UserVote(voterUserId);
+
+            if (vote == null)
+            {
+                vote = new Vote()
+                {
+                    UserId = voterUserId,
+                    LinkId = Id,
+                    Score = score,
+                    DateTime = DateTime.Now
+                };
+
+                Votes.Add(vote);
+            }
+            else
+            {
+                vote.Score = vote.Score == score ? 0 : score;
+            }
+        }
     }
 }

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Models\Link.cs - add UserVote and Vote methods'
# ----------------------------------------------------------------------
@"
diff --git a/Pages/Links/Index.cshtml.cs b/Pages/Links/Index.cshtml.cs
index d864cb8..817d523 100644
--- a/Pages/Links/Index.cshtml.cs
+++ b/Pages/Links/Index.cshtml.cs
@@ -32,5 +32,24 @@ namespace LinkAggregator.Pages.Links
                 .Include(link => link.Votes)
                 .ToListAsync();
         }
+
+        public async Task<IActionResult> OnPostVoteAsync(int id, int score)
+        {
+            if (User == null)
+                return RedirectToPage();
+
+            if (User.Identity.IsAuthenticated == false)
+                return RedirectToPage();
+                        
+            var link = _context.Link
+                .Include(link => link.Votes)
+                .First(link => link.Id == id);
+                        
+            await link.Vote(score, UserManager.GetUserId(User));
+
+            await _context.SaveChangesAsync();
+
+            return RedirectToPage("./Index");
+        }
     }
 }

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links\Index.cshtml.cs - OnPostVoteAsync'
# ----------------------------------------------------------------------

# # Vote buttons

@"
diff --git a/Pages/Links/Index.cshtml b/Pages/Links/Index.cshtml
index d6c354b..320174c 100644
--- a/Pages/Links/Index.cshtml
+++ b/Pages/Links/Index.cshtml
@@ -41,6 +41,23 @@
             <td>
                 @Html.DisplayFor(modelItem => link.DateTime)
             </td>
+
+            <td>
+                <form asp-page-handler="Vote" style="display:inline" method="post">
+                    <input type="hidden" name="id" value="@link.Id" />
+                    <input type="hidden" name="score" value="1" />
+                    <button type="submit">U</button>
+                </form>
+               
+                @link.Score()
+ 
+                <form asp-page-handler="Vote" style="display:inline" method="post">
+                    <input type="hidden" name="id" value="@link.Id" />
+                    <input type="hidden" name="score" value="-1" />
+                    <button type="submit">D</button>
+                </form>                
+            </td>
+
             <td>
                 <a asp-page="./Edit" asp-route-id="@link.Id">Edit</a> |
                 <a asp-page="./Details" asp-route-id="@link.Id">Details</a> |

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links\Index.cshtml - vote buttons'
# ----------------------------------------------------------------------
# Add `UserScore` method. If the given user has voted up a link, it returns `1`. If the user has voted down a link, it returns `-1`. Otherwise, it returns `0`.

@"
diff --git a/Models/Link.cs b/Models/Link.cs
index 8c2693a..67bee47 100644
--- a/Models/Link.cs
+++ b/Models/Link.cs
@@ -26,6 +26,13 @@ namespace LinkAggregator.Models
 
         public Vote UserVote(string userId) => Votes.FirstOrDefault(vote => vote.UserId == userId);
 
+        public int UserScore(string userId)
+        {
+            var vote = UserVote(userId);
+
+            return vote == null ? 0 : vote.Score;
+        }
+
         public async Task Vote(int score, string voterUserId)
         {
             var vote = UserVote(voterUserId);

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Link - UserScore'
# ----------------------------------------------------------------------
@"
diff --git a/Pages/Links/Index.cshtml.cs b/Pages/Links/Index.cshtml.cs
index 817d523..0d52386 100644
--- a/Pages/Links/Index.cshtml.cs
+++ b/Pages/Links/Index.cshtml.cs
@@ -31,8 +31,11 @@ namespace LinkAggregator.Pages.Links
             Links = await _context.Link
                 .Include(link => link.Votes)
                 .ToListAsync();
+
         }
 
+        public string CurrentUserid() => UserManager.GetUserId(User);
+
         public async Task<IActionResult> OnPostVoteAsync(int id, int score)
         {
             if (User == null)

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Index.cshtml.cs - CurrentUserId method'
# ----------------------------------------------------------------------
# Use `UserScore` method to indicate with CSS if user has voted on a link.
@"
diff --git a/Pages/Links/Index.cshtml b/Pages/Links/Index.cshtml
index 320174c..a52f0a9 100644
--- a/Pages/Links/Index.cshtml
+++ b/Pages/Links/Index.cshtml
@@ -46,15 +46,15 @@
                 <form asp-page-handler="Vote" style="display:inline" method="post">
                     <input type="hidden" name="id" value="@link.Id" />
                     <input type="hidden" name="score" value="1" />
-                    <button type="submit">U</button>
+                    <button class="btn @(link.UserScore(Model.CurrentUserid()) == 1 ? "btn-primary" : "btn-secondary")" type="submit">U</button>
                 </form>
-               
+                                               
                 @link.Score()
  
                 <form asp-page-handler="Vote" style="display:inline" method="post">
                     <input type="hidden" name="id" value="@link.Id" />
                     <input type="hidden" name="score" value="-1" />
-                    <button type="submit">D</button>
+                    <button class="btn @(link.UserScore(Model.CurrentUserid()) == -1 ? "btn-primary" : "btn-secondary")" type="submit">D</button>
                 </form>                
             </td>
 

"@ | git apply --whitespace=nowarn

    git add . ; git commit --message 'Pages\Links\Index.cshtml - indicate if user voted'
# ----------------------------------------------------------------------

# # Test the project with Canopy

# Create the test project

    dotnet new console --language f# --output Test
    
    # dotnet sln MvcMovieSaturn.sln add src/Test
    
    dotnet add Test/Test.fsproj package canopy
    
    dotnet add Test/Test.fsproj package Selenium.WebDriver.ChromeDriver

    # dotnet run --project .\Test\Test.fsproj

# Create the unit tests file






function reset-database ()
{
    dotnet ef database drop -f
    dotnet ef database update
}

function run_app ()
{
    $items = 'dotnet run' -split ' '

    Start-Process $items[0] $items[1..100] -PassThru
}

function run_canopy ()
{
    $dir = (Resolve-Path .).Path

    $code = {
        param($dir)

        cd $dir
        dotnet run --project .\Test\Test.fsproj 
    }

    $job_canopy = Start-Job -ScriptBlock $code -ArgumentList $dir


    while ($job_canopy.State -ne 'Completed')
    {
        Start-Sleep -Seconds 2
    }

    Receive-Job $job_canopy
}

    

    dotnet run --project .\Test\Test.fsproj






function test-app()
{
    reset-database
    
    $proc = run_app
    
    run_canopy

    Stop-Process $proc.Id
}


test-app

Copy-Item .\screenshot-links.jpg ..

