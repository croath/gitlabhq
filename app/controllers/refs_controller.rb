class RefsController < ProjectResourceController

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  before_filter :ref
  before_filter :define_tree_vars, only: [:blob, :logs_tree]

  def switch
    respond_to do |format|
      format.html do
        new_path = if params[:destination] == "tree"
                     project_tree_path(@project, (@ref + "/" + params[:path]))
                   elsif params[:destination] == "blob"
                     project_blob_path(@project, (@ref + "/" + params[:path]))
                   elsif params[:destination] == "graph"
                     project_graph_path(@project, @ref)
                   else
                     project_commits_path(@project, @ref)
                   end

        redirect_to new_path
      end
      format.js do
        @ref = params[:ref]
        define_tree_vars
        render "tree"
      end
    end
  end

  def logs_tree
    contents = @tree.entries
    @logs = contents.map do |content|
      file = params[:path] ? File.join(params[:path], content.name) : content.name
      last_commit = @repo.commits(@commit.id, file, 1).last
      {
        file_name: content.name,
        commit: last_commit
      }
    end
  end

  protected

  def define_tree_vars
    params[:path] = nil if params[:path].blank?

    @repo = project.repository
    @commit = @repo.commit(@ref)
    @tree = Tree.new(@repo, @commit.id, @ref, params[:path])
    @hex_path = Digest::SHA1.hexdigest(params[:path] || "")

    if params[:path]
      @logs_path = logs_file_project_ref_path(@project, @ref, params[:path])
    else
      @logs_path = logs_tree_project_ref_path(@project, @ref)
    end
  rescue
    return render_404
  end

  def ref
    @ref = params[:id] || params[:ref]
  end
end
