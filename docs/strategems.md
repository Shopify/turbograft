# TurboGraft Stratagems

## Strategems through example

### Remote partials

*Potential Desires:*
- Avoid rendering an expensive partial inline, fetch from the server on click
- `Show more...` type links

*Example:*

`views/users/index.html.erb`

```erb
<% @users.each do |user| %>
 <%= render 'detailed_user', user: user %>
<% end %>
```

`views/users/_detailed_user.html.erb`

```erb
<div id="user_details_<%= user.id %>" refresh="user_details_<%= user.id %>">
  <p>Name</p>
  <p><%= user.name %></p>
  <% if local_assigns[:detailed].present? %>
    <p><%= user.email %></p>
    <p><%= user.favourite_food %></p>
  <% else %>
    <%= link_to "Show more details...", show_more_details_user_path(user), 'tg-remote' => 'GET', 'refresh-on-success' => "user_details_#{user.id}" %>
  <% end %>
</div>
```

`users_controller.rb`

```rb
  def show_more_details
    render 'detailed_user', locals: {user: @user, detailed: true}, layout: false, status: :ok
  end
```

*Discussion:*

The above formulation allows the user to click the link, the server to render and return just a small snippet of HTML, and the browser to replace the `#user_details_<ID>` DIV with an updated copy of itself.  The result is a very small HTTP payload and a single render path.

---

### Perform an action and refresh everything

*Potential Desires:*
- Perform an expensive operation, discard client state (like a total repaint)
- Refresh a resource
- Perform an action, and render anything you desire via the controller

*Example*:

`views/comments/index.html.erb`

```erb
<% @comments.each do |comment| %>
  <div class="comment">
    <span><%= comment.author %></span>
    <span><%= comment.body %></span>
    <span><%= comment.timestamp %></span>
  </div>
<% end %>
<%= link_to 'Refresh comment list', comments_index_path, 'tg-remote' => 'GET' %>
```

*Discussion:*

Clicking the above link is understood to mean doing a GET for the currently displayed page.  The `<body>` of the HTTP response is swapped in, and the current `<body>` is swapped out.  This can be seen as an easy way to implement a hard `Refresh` button.

But what if you wanted to perform an action that modifies state?

*Example*:

`views/comments/index.html.erb`

```erb
<% @comments.each do |comment| %>
  <div class="comment">
    <span><%= comment.author %></span>
    <span><%= comment.body %></span>
    <span><%= comment.timestamp %></span>
    <%= link_to 'Delete comment', destroy_comment_path(comment), 'tg-remote' => 'DELETE' %>
    <%= link_to 'Mark as spam', spam_comment_path(comment), 'tg-remote' => 'PUT' %>
  </div>
<% end %>
```

`comments_controller.rb`

```rb
def destroy_comment
  if @comment.destroy
    redirect_to comments_index_path, notice: 'Comment destroyed!'
  else
    redirect_to comments_index_path, error: 'Comment could not be destroyed.'
  end
end

def spam_comment
  # ... similar to above
end
```

*Discussion:*

This example could be considered as fairly wasteful since the entire DOM is re-rendered on the server and replaced, but we've only updated or removed a single comment.

---

### Simple CRUD with error messaging

*Potential Desires:*
- We all need this one at some point :)

*Example:*

`views/posts/_form.html.erb`

```erb
<%= form_for(@post), method: 'POST', 'tg-remote' => true, 'refresh-on-error' => 'posts-errors' do |f| %>
  <div id="posts-errors" class="errors" refresh="posts-errors">
    <% if @post.errors.size %>
      <!-- print out your errors nicely here -->
    <% end %>
  </div>
  <div class="fields">
    <!-- your inputs go here -->
    <%= f.submit :Save %>
  </div>
<% end %>
```

`posts_controller.rb`

```ruby
def create
  @post = Post.create(post_params)

  if @post.save
    redirect_to posts_path(@post), notice: "Your post has been created."
  else
    render :new, status: :unprocessable_entity
  end
end
```

*Discussion:*

The above allows you to re-render the same template as before, but with an updated `#posts-errors` DIV.  To note, `:unprocessable_entity` (aka HTTP 422) is required by TurboGraft to consider the replacement viable on error.  Any other HTTP status code will not re-render.  If all goes well, we're redirecting to the `#show` page to see the new post we just created.

---

### Fire and forget

*Potential Desires:*
- Perform an expensive action, but we don't care at all about presenting results or feedback of any kind to the user (e.g., perhaps we're handling visual feedback through JS)
- Dismiss a notification

*Example:*

`views/home/index.html.erb`

```erb
<div class="notification">
  <div class="notification-body">
    <p>Heads up!  There's a new feature for you to use:</p>
    ...
  </div>
  <div class="close-button">
    <%= link_to 'Close', dismiss_notification_path(some_notification_id), 'tg-remote' => 'DELETE', 'tg-remote-norefresh' => true, 'remote-once' => true, class: 'close-button-icon', onclick: '$(this).parents('.notification').remove()' %>
  </div>
</div>
```

`notification_controller.rb`

```rb
def dismiss_notification
  # dismiss it
  head :ok
end
```

*Discussion:*

When you need to handle UI state in the client, it can be desirable to just fire the request and forget about any response.  This is useful when you don't care to notify a user about the success or failure of an operation.  `remote-once` ensures that we only perform this action exactly once.

---

### Maintaining client-state, preventing partial refresh of an element

*Potential Desires*:
- You have a client-side JS navigation
- You have an `<audio>` or `<video>` element on your page, and you want to be sure it keeps playing while other aspects of the page refreshes
- You have any kind of long-lived singleton-style DOM element

*Example:*

`layout/application.html.erb`

```erb
<nav id="SideNav" tg-static>
  <a>Home</a>
  <a>Blog</a>
  <a>Pages</a>
  ...
</nav>
<section id="MainContent">
  <%= yield %>
</section>
```

*Discussion*:

Elements inside your `#MainContent` can be perform partial refreshes or turbolinks navigations (full `<body>` swaps), but the `tg-static` elements will always be kept in place.  Thus, any client-side state (e.g., modifications to `class` or DOM innards) will persist.  One thing to note is that CSS animations/transitions on or inside this node will not continue from where they left off; they will immediately halt after temporary removal from the DOM.

---

### Performing an action after a tg-remote completes

*Potential Desires*:
- Scripting UI to change after part of the page has refreshed
- Displaying and stopping a loading indicator

*Example:*

If you grab the DOM element for the `tg-remote` in question, you can attach a listener to one of the `tg-remote` events.

```coffee
form = document.getElementById('#myForm')
form.addEventListener "turbograft:remote:success", doSomethingCool
form.submit() # or potentially this happened via user in the UI
```

---

### Cleaning up after yourself

*Potential Desires*:
- Cleaning up event handlers you've bound on nodes that no longer exist
- Implementing the concept of a destructor for a component that's heavily tied to a DOM node

```coffee
class CoolComponent
  constructor: (@node) ->
    # ... just constructor things
    Page.onReplace(@node, @destructor.bind(this))

  destructor: ->
    # runs when @node disappears from the DOM
```

```coffee
myInstance = new CoolComponent(document.getElementById('#someComponent'))
```

*Discussion*:

In this usage, you can instantiate a class who's lifecycle is tied directly to its presence in the DOM.  `Page.onReplace(node, ->)` is provided by TurboGraft to run a function before the node gets removed.  With this API, we can do any clean-up to keep our app snappy, and prevent bugs from long-lived event handlers firing when they shouldn't.

---

### When to render, when to redirect, when to X-Next-Redirect?

- You could render a completely different page as the response to a `tg-remote`, but keep in mind the URL will not update
- `redirect_to` will cause the URL to update correctly
- Setting `response.headers['X-Next-Redirect']` to a path will cause turbograft to completely ignore the response of any XHR, and do a hard navigation to another page.  This can be useful when you want to partially refresh a section 99% of the time, but have a 1% case where you need to direct the user elsewhere.  Examples can include:  refreshing a search when there's many results (common), but redirect to the result in question when there's 1 result (uncommon); refreshing a part of a page (common), but redirecting to a blocking "Login" page when the user's session has expired (less common).
