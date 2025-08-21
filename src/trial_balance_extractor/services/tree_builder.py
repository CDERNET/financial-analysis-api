"""Tree building service for hierarchical account structures."""

import logging
from typing import List, Dict, Any, Set
from ..models.schemas import TreeNode, TrialBalanceItem
from ..utils.text_processing import find_parent_code


logger = logging.getLogger(__name__)


class TreeBuilder:
    """Service for building hierarchical tree structures from flat data."""
    
    def build_tree_from_items(
        self, 
        items: List[TrialBalanceItem],
        account_code_field: str = "account_code",
        parent_code_field: str = "parent_account_code"
    ) -> List[TreeNode]:
        """
        Build tree structure from flat list of TrialBalanceItem objects.
        
        Args:
            items: List of trial balance items
            account_code_field: Field name for account code
            parent_code_field: Field name for parent account code
            
        Returns:
            List of root TreeNode objects
        """
        if not items:
            logger.warning("No items provided for tree building")
            return []
        
        # Create lookup dictionary
        item_dict = {}
        for item in items:
            code = getattr(item, account_code_field)
            if code:
                item_dict[code] = TreeNode(
                    account_code=item.account_code,
                    account_name=item.account_name,
                    debit=item.debit,
                    credit=item.credit,
                    debit_balance=item.debit_balance,
                    credit_balance=item.credit_balance,
                    parent_account_code=item.parent_account_code,
                    children=[]
                )
        
        # Build parent-child relationships
        root_nodes = []
        for item in items:
            code = getattr(item, account_code_field)
            parent_code = getattr(item, parent_code_field)
            
            if code and code in item_dict:
                node = item_dict[code]
                
                if parent_code and parent_code in item_dict:
                    # Add as child to parent
                    parent_node = item_dict[parent_code]
                    parent_node.children.append(node)
                else:
                    # This is a root node
                    root_nodes.append(node)
        
        logger.info(f"Built tree with {len(root_nodes)} root nodes")
        return root_nodes
    
    def build_tree_from_dict(
        self,
        data: List[Dict[str, Any]],
        account_code_field: str = "AccountCode",
        parent_code_field: str = "ParentAccountCode"
    ) -> List[TreeNode]:
        """
        Build tree structure from dictionary data.
        
        Args:
            data: List of dictionaries containing account data
            account_code_field: Field name for account code
            parent_code_field: Field name for parent account code
            
        Returns:
            List of root TreeNode objects
        """
        if not data:
            logger.warning("No data provided for tree building")
            return []
        
        # Create lookup dictionary
        node_dict = {}
        for item in data:
            code = item.get(account_code_field)
            if code:
                node_dict[code] = TreeNode(
                    account_code=str(code),
                    account_name=str(item.get('AccountName', '')),
                    debit=float(item.get('Debit', 0)),
                    credit=float(item.get('Credit', 0)),
                    debit_balance=float(item.get('DebitBalance', 0)),
                    credit_balance=float(item.get('CreditBalance', 0)),
                    parent_account_code=item.get(parent_code_field),
                    children=[]
                )
        
        # Build parent-child relationships
        root_nodes = []
        for item in data:
            code = item.get(account_code_field)
            parent_code = item.get(parent_code_field)
            
            if code and code in node_dict:
                node = node_dict[code]
                
                if parent_code and parent_code in node_dict:
                    # Add as child to parent
                    parent_node = node_dict[parent_code]
                    parent_node.children.append(node)
                else:
                    # This is a root node
                    root_nodes.append(node)
        
        logger.info(f"Built tree with {len(root_nodes)} root nodes from dictionary data")
        return root_nodes
    
    def flatten_tree(self, tree_nodes: List[TreeNode]) -> List[TrialBalanceItem]:
        """
        Flatten tree structure back to list of TrialBalanceItem objects.
        
        Args:
            tree_nodes: List of root tree nodes
            
        Returns:
            Flattened list of TrialBalanceItem objects
        """
        items = []
        
        def _flatten_recursive(node: TreeNode, account_number: int, period_id: int):
            """Recursively flatten tree nodes."""
            item = TrialBalanceItem(
                account_code=node.account_code,
                account_name=node.account_name,
                debit=node.debit,
                credit=node.credit,
                debit_balance=node.debit_balance,
                credit_balance=node.credit_balance,
                parent_account_code=node.parent_account_code,
                account_number=account_number,
                period_id=period_id
            )
            items.append(item)
            
            # Process children
            for child in node.children:
                _flatten_recursive(child, account_number, period_id)
        
        # Process all root nodes
        for root_node in tree_nodes:
            _flatten_recursive(root_node, 0, 0)  # Default values for flattening
        
        logger.info(f"Flattened tree to {len(items)} items")
        return items
    
    def calculate_hierarchy_levels(self, tree_nodes: List[TreeNode]) -> Dict[str, int]:
        """
        Calculate hierarchy level for each account code.
        
        Args:
            tree_nodes: List of root tree nodes
            
        Returns:
            Dictionary mapping account codes to their hierarchy levels
        """
        levels = {}
        
        def _calculate_levels(node: TreeNode, level: int):
            """Recursively calculate levels."""
            levels[node.account_code] = level
            for child in node.children:
                _calculate_levels(child, level + 1)
        
        # Process all root nodes starting at level 0
        for root_node in tree_nodes:
            _calculate_levels(root_node, 0)
        
        logger.info(f"Calculated levels for {len(levels)} account codes")
        return levels
    
    def get_tree_statistics(self, tree_nodes: List[TreeNode]) -> Dict[str, Any]:
        """
        Get statistics about the tree structure.
        
        Args:
            tree_nodes: List of root tree nodes
            
        Returns:
            Dictionary containing tree statistics
        """
        total_nodes = 0
        max_depth = 0
        leaf_nodes = 0
        
        def _analyze_tree(node: TreeNode, depth: int):
            """Recursively analyze tree structure."""
            nonlocal total_nodes, max_depth, leaf_nodes
            
            total_nodes += 1
            max_depth = max(max_depth, depth)
            
            if not node.children:
                leaf_nodes += 1
            
            for child in node.children:
                _analyze_tree(child, depth + 1)
        
        # Analyze all root nodes
        for root_node in tree_nodes:
            _analyze_tree(root_node, 0)
        
        stats = {
            "total_nodes": total_nodes,
            "root_nodes": len(tree_nodes),
            "leaf_nodes": leaf_nodes,
            "max_depth": max_depth,
            "internal_nodes": total_nodes - leaf_nodes
        }
        
        logger.info(f"Tree statistics: {stats}")
        return stats
