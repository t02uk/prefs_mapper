package <%= @namespace %>

import android.content.Context
import android.content.SharedPreferences
import android.preference.PreferenceManager

/**
 * config file loader
 *
 */

object <%= @class_name %> {

  <%- @items.each do |item| %>
  /**
   * <%= item.title %>
   */
  private[this] var _<%= item.name %>: <%= item.type %> = _
  def <%= item.name %>: <%= item.type %> = _<%= item.name %>
  <%- end %>

  object Keys {
    <%- @items.each do |item| -%>
    val <%= item.name %> = "<%= item.name %>"
    <%- end %>
  }

//private[this] var registered = false
//  /**
//   *
//   */
//  def registerListener(context: Context, key: String, listener: SharedPreferences) {
//    val prefs = PreferenceManager.getDefaultSharedPreferences(context)
//    if(!registered) {
//      prefs.registerOnSharedPreferenceChangeListener(listener)
//      registered = true
//    }
//    onSharedPreferenceChanged(prefs, key)
//  }
//
//  def registerListener(context: Context, listener: SharedPreferences) {
//    val prefs = PreferenceManager.getDefaultSharedPreferences(context)
//    if(!registered) {
//      prefs.registerOnSharedPreferenceChangeListener(listener)
//      registered = true
//    }
//    <%- @items.each do |item| -%>
//    // register key: <%= item.name %>
//    listener.onSharedPreferenceChanged(prefs, "<%= item.name %>")
//    <%- end %>
//  }

  /**
   * Load on preference with key
   */
  def load(context: Context, key: String) {
    val prefs = PreferenceManager.getDefaultSharedPreferences(context)
    key match {
      <%- @items.each_with_index do |item| -%>
      case "<%= item.name %>" => _<%= item.name %> = prefs.<%= item.load_method %>
      <%- end -%>
    }
  }

  /**
   * Load all preference
   */
  def loadAll(context: Context) {
    val prefs = PreferenceManager.getDefaultSharedPreferences(context)
    <%- @items.each do |item| %>
    // load value: <%= item.name %>
    _<%= item.name %> = prefs.<%= item.load_method -%>
    <%- end %>
  }
}
